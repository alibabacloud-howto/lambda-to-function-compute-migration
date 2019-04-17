/**
 * Infrastructure for the database, lambda and related resources.
 *
 * @author Alibaba Cloud
 */

provider "aws" {
  region = "ap-south-1"
}

// VPC and subnet
resource "aws_vpc" "outpg_vpc" {
  cidr_block = "192.168.0.0/16"
}
data "aws_availability_zones" "outpg_zones" {
}
resource "aws_subnet" "outpg_subnet_1" {
  vpc_id = "${aws_vpc.outpg_vpc.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone_id = "${data.aws_availability_zones.outpg_zones.zone_ids[0]}"
}
resource "aws_subnet" "outpg_subnet_2" {
  vpc_id = "${aws_vpc.outpg_vpc.id}"
  cidr_block = "192.168.2.0/24"
  availability_zone_id = "${data.aws_availability_zones.outpg_zones.zone_ids[1]}"
}

// Security group
resource "aws_security_group" "outpg_security_group" {
  name = "outpg-security-group"
  vpc_id = "${aws_vpc.outpg_vpc.id}"

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

// Database
resource "aws_db_subnet_group" "outpg_db_subnet_group" {
  name = "outpg-db-subnet-group"
  subnet_ids = [
    "${aws_subnet.outpg_subnet_1.id}",
    "${aws_subnet.outpg_subnet_2.id}"
  ]
}
resource "aws_db_instance" "outpg_db_instance" {
  engine = "postgres"
  engine_version = "9.4.20"
  allocated_storage = 5
  instance_class = "db.t2.micro"
  storage_type = "standard"
  identifier_prefix = "outpg-db-instance"
  name = "${var.db_name}"
  username = "${var.db_user}"
  password = "${var.db_password}"
  vpc_security_group_ids = [
    "${aws_security_group.outpg_security_group.id}"
  ]
  db_subnet_group_name = "${aws_db_subnet_group.outpg_db_subnet_group.name}"
  skip_final_snapshot = true
}

// CloudWatch log group
resource "aws_cloudwatch_log_group" "outpg_log_group" {
  name = "/aws/lambda/outpg"
  retention_in_days = 14
}

// Lambda role
resource "aws_iam_role" "outpg_lambda_role" {
  name = "outpg_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Sid": "",
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_policy" "outpg_lambda_policy" {
  name = "outpg_lambda_policy"
  path = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "${aws_cloudwatch_log_group.outpg_log_group.arn}:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "outpg_lambda_policy_attachment" {
  role = "${aws_iam_role.outpg_lambda_role.name}"
  policy_arn = "${aws_iam_policy.outpg_lambda_policy.arn}"
}

// Lambda
resource "aws_lambda_function" "outpg_lambda" {
  filename = "../target/outpg.zip"
  function_name = "outpg"
  role = "${aws_iam_role.outpg_lambda_role.arn}"
  handler = "index.handler"
  source_code_hash = "${filebase64sha256("../target/outpg.zip")}"
  runtime = "nodejs8.10"
  timeout = 30

  vpc_config {
    subnet_ids = [
      "${aws_subnet.outpg_subnet_1.id}"
    ]
    security_group_ids = [
      "${aws_security_group.outpg_security_group.id}"
    ]
  }

  environment = {
    variables = {
      host = "${aws_db_instance.outpg_db_instance.address}",
      port = "${aws_db_instance.outpg_db_instance.port}",
      database = "${var.db_name}",
      username = "${var.db_user}",
      password = "${var.db_password}"
    }
  }
}
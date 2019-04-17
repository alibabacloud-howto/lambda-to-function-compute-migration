/**
 * Basic lambda that just logs messages.
 *
 * @author Alibaba Cloud
 */

provider "aws" {
  region = "ap-south-1"
}


//
// Create the lambda.
//

resource "aws_iam_role" "basic_lambda_role" {
  name = "basic_lambda_role"

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

resource "aws_lambda_function" "basic_lambda" {
  filename = "target/basic.zip"
  function_name = "basic"
  role = "${aws_iam_role.basic_lambda_role.arn}"
  handler = "index.handler"
  source_code_hash = "${filebase64sha256("target/basic.zip")}"
  runtime = "nodejs8.10"
}


//
// Create the log group and attach the policy to the lambda.
//

resource "aws_cloudwatch_log_group" "basic_log_group" {
  name = "/aws/lambda/${aws_lambda_function.basic_lambda.function_name}"
  retention_in_days = 14
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_policy" "basic_logging_policy" {
  name = "basic_lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.basic_log_group.name}:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "basic_logging_policy_attachment" {
  role = "${aws_iam_role.basic_lambda_role.name}"
  policy_arn = "${aws_iam_policy.basic_logging_policy.arn}"
}
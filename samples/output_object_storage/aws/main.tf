/**
 * Lambda that read and write a file on S3.
 *
 * @author Alibaba Cloud
 */

provider "aws" {
  region = "ap-south-1"
}


//
// Create the lambda.
//

resource "aws_iam_role" "outobjstorage_lambda_role" {
  name = "outobjstorage_lambda_role"

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

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_lambda_function" "outobjstorage_lambda" {
  filename = "target/output-object-storage.zip"
  function_name = "output-object-storage"
  role = "${aws_iam_role.outobjstorage_lambda_role.arn}"
  handler = "index.handler"
  source_code_hash = "${filebase64sha256("target/output-object-storage.zip")}"
  runtime = "nodejs8.10"

  environment = {
    variables = {
      bucketName = "${aws_s3_bucket.outobjstorage_bucket.bucket}"
    }
  }
}


//
// Create the log group and attach the policy to the lambda.
//

resource "aws_cloudwatch_log_group" "outobjstorage_log_group" {
  name = "/aws/lambda/${aws_lambda_function.outobjstorage_lambda.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "outobjstorage_logging_policy" {
  name = "outobjstorage_lambda_logging"
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
      "Resource": "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.outobjstorage_log_group.name}:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "outobjstorage_logging_policy_attachment" {
  role = "${aws_iam_role.outobjstorage_lambda_role.name}"
  policy_arn = "${aws_iam_policy.outobjstorage_logging_policy.arn}"
}


//
// Create a S3 bucket and allow the lambda to read and write on it.
//

resource "aws_s3_bucket" "outobjstorage_bucket" {
  bucket_prefix = "outobjstorage-bucket"
}

resource "aws_s3_bucket_object" "outobjstorage_bucket_object" {
  bucket = "${aws_s3_bucket.outobjstorage_bucket.bucket}"
  key = "test.txt"
  content = "sample-test-content"
}

resource "aws_iam_policy" "outobjstorage_bucket_policy" {
  name = "outobjstorage_lambda_bucket"
  path = "/"
  description = "IAM policy for reading and writing files on S3."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.outobjstorage_bucket.arn}/*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "outobjstorage_bucket_policy_attachment" {
  role = "${aws_iam_role.outobjstorage_lambda_role.name}"
  policy_arn = "${aws_iam_policy.outobjstorage_bucket_policy.arn}"
}
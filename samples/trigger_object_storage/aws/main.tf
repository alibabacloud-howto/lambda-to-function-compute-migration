/**
 * Lambda triggered when a file is created into a S3 bucket.
 *
 * @author Alibaba Cloud
 */

provider "aws" {
  region = "ap-south-1"
}


//
// Create the lambda.
//

resource "aws_iam_role" "storage_lambda_role" {
  name = "storage_lambda_role"

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

resource "aws_lambda_function" "storage_lambda" {
  filename = "target/object_storage.zip"
  function_name = "storage"
  role = "${aws_iam_role.storage_lambda_role.arn}"
  handler = "index.handler"
  source_code_hash = "${filebase64sha256("target/object_storage.zip")}"
  runtime = "nodejs8.10"
}

//
// Create the log group and attach the policy to the lambda.
//

resource "aws_cloudwatch_log_group" "storage_log_group" {
  name = "/aws/lambda/${aws_lambda_function.storage_lambda.function_name}"
  retention_in_days = 14
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_policy" "storage_logging_policy" {
  name = "storage_lambda_logging"
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
      "Resource": "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.storage_log_group.name}:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "storage_logging_policy_attachment" {
  role = "${aws_iam_role.storage_lambda_role.name}"
  policy_arn = "${aws_iam_policy.storage_logging_policy.arn}"
}


//
// Create a bucket
//

resource "aws_s3_bucket" "storage_bucket" {
  bucket_prefix = "storage-bucket"
}

//
// Trigger the lambda when an object is created in the bucket.
//

resource "aws_lambda_permission" "storage_permission" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.storage_lambda.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "${aws_s3_bucket.storage_bucket.arn}"
}

resource "aws_s3_bucket_notification" "storage_notification" {
  bucket = "${aws_s3_bucket.storage_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.storage_lambda.arn}"
    events = [
      "s3:ObjectCreated:*"
    ]
  }
}
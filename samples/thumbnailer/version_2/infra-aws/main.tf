/**
 * Infrastructure for the lambda and related cloud resources (S3 bucket, SQS queue, ...).
 *
 * @author Alibaba Cloud
 */

provider "aws" {
  region = "ap-south-1"
}

// S3 bucket
resource "aws_s3_bucket" "thumbnailer_bucket" {
  bucket_prefix = "thumbnailer-bucket"
}
resource "aws_s3_bucket_object" "thumbnailer_bucket_images_readme" {
  bucket = "${aws_s3_bucket.thumbnailer_bucket.bucket}"
  key = "images/README.TXT"
  content = "Upload images here."
}
resource "aws_s3_bucket_object" "thumbnailer_bucket_thumbnails_readme" {
  bucket = "${aws_s3_bucket.thumbnailer_bucket.bucket}"
  key = "thumbnails/README.TXT"
  content = "Thumbnails are saved here."
}

// SQS queue
resource "aws_sqs_queue" "thumbnailer_queue" {
  name = "thumbnailer-queue"
}

// CloudWatch log group
resource "aws_cloudwatch_log_group" "thumbnailer_log_group" {
  name = "/aws/lambda/thumbnailer"
  retention_in_days = 14
}

// Lambda role
resource "aws_iam_role" "thumbnailer_lambda_role" {
  name = "thumbnailer_lambda_role"

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
resource "aws_iam_policy" "thumbnailer_lambda_policy" {
  name = "thumbnailer_lambda_policy"
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
      "Resource": "${aws_cloudwatch_log_group.thumbnailer_log_group.arn}:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.thumbnailer_bucket.arn}/*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.thumbnailer_queue.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "thumbnailer_lambda_policy_attachment" {
  role = "${aws_iam_role.thumbnailer_lambda_role.name}"
  policy_arn = "${aws_iam_policy.thumbnailer_lambda_policy.arn}"
}

// Lambda
resource "aws_lambda_function" "thumbnailer_lambda" {
  filename = "../target/thumbnailer.zip"
  function_name = "thumbnailer"
  role = "${aws_iam_role.thumbnailer_lambda_role.arn}"
  handler = "indexaws.handler"
  source_code_hash = "${filebase64sha256("../target/thumbnailer.zip")}"
  runtime = "nodejs8.10"
  timeout = 30

  environment = {
    variables = {
      queueUrl = "${aws_sqs_queue.thumbnailer_queue.id}"
    }
  }
}

// S3 bucket notification and permission
resource "aws_s3_bucket_notification" "thumbnailer_notification" {
  bucket = "${aws_s3_bucket.thumbnailer_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.thumbnailer_lambda.arn}"
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_prefix = "images/"
  }
}
resource "aws_lambda_permission" "thumbnailer_permission" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.thumbnailer_lambda.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "${aws_s3_bucket.thumbnailer_bucket.arn}"
}
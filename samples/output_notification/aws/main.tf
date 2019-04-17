/**
 * Lambda that send a message into a SQS queue.
 *
 * @author Alibaba Cloud
 */

provider "aws" {
  region = "ap-south-1"
}


//
// Create the lambda.
//

resource "aws_iam_role" "outnotification_lambda_role" {
  name = "outnotification_lambda_role"

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

resource "aws_lambda_function" "outnotification_lambda" {
  filename = "target/output-notification.zip"
  function_name = "output-notification"
  role = "${aws_iam_role.outnotification_lambda_role.arn}"
  handler = "index.handler"
  source_code_hash = "${filebase64sha256("target/output-notification.zip")}"
  runtime = "nodejs8.10"

  environment = {
    variables = {
      queueUrl = "https://sqs.${data.aws_region.current.id}.amazonaws.com/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.outnotification_queue.name}"
    }
  }
}


//
// Create the log group and attach the policy to the lambda.
//

resource "aws_cloudwatch_log_group" "outnotification_log_group" {
  name = "/aws/lambda/${aws_lambda_function.outnotification_lambda.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "outnotification_logging_policy" {
  name = "outnotification_lambda_logging"
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
      "Resource": "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.outnotification_log_group.name}:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "outnotification_logging_policy_attachment" {
  role = "${aws_iam_role.outnotification_lambda_role.name}"
  policy_arn = "${aws_iam_policy.outnotification_logging_policy.arn}"
}


//
// Create a SQS queue and allow the lambda to write into it.
//

resource "aws_sqs_queue" "outnotification_queue" {
  name = "outnotification-queue"
}

resource "aws_iam_policy" "outnotification_sqs_policy" {
  name = "outnotification_lambda_sqs"
  path = "/"
  description = "IAM policy for sending messages to SQS."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "${aws_sqs_queue.outnotification_queue.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "outnotification_sqs_policy_attachment" {
  role = "${aws_iam_role.outnotification_lambda_role.name}"
  policy_arn = "${aws_iam_policy.outnotification_sqs_policy.arn}"
}
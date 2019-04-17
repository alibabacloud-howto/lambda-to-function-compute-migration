/**
 * Lambda triggered when a message is sent to a SQS queue.
 *
 * @author Alibaba Cloud
 */

provider "aws" {
  region = "ap-south-1"
}


//
// Create the lambda.
//

resource "aws_iam_role" "notification_lambda_role" {
  name = "notification_lambda_role"

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

resource "aws_lambda_function" "notification_lambda" {
  filename = "target/notification.zip"
  function_name = "notification"
  role = "${aws_iam_role.notification_lambda_role.arn}"
  handler = "index.handler"
  source_code_hash = "${filebase64sha256("target/notification.zip")}"
  runtime = "nodejs8.10"
}

//
// Create the log group and attach the policy to the lambda.
//

resource "aws_cloudwatch_log_group" "notification_log_group" {
  name = "/aws/lambda/${aws_lambda_function.notification_lambda.function_name}"
  retention_in_days = 14
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_policy" "notification_logging_policy" {
  name = "notification_lambda_logging"
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
      "Resource": "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.notification_log_group.name}:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "notification_logging_policy_attachment" {
  role = "${aws_iam_role.notification_lambda_role.name}"
  policy_arn = "${aws_iam_policy.notification_logging_policy.arn}"
}


//
// Create a SQS queue
//

resource "aws_sqs_queue" "notification_queue" {
  name = "notification-queue"
}

//
// Trigger the lambda when a message is sent into the queue.
//

resource "aws_lambda_event_source_mapping" "notification_event_source_mapping" {
  batch_size = 10
  event_source_arn = "${aws_sqs_queue.notification_queue.arn}"
  enabled = true
  function_name = "${aws_lambda_function.notification_lambda.arn}"
}

resource "aws_iam_policy" "notification_sqs_policy" {
  name = "notification_lambda_sqs"
  path = "/"
  description = "IAM policy for reading messages from SQS."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:ChangeMessageVisibility",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ReceiveMessage"
      ],
      "Resource": "${aws_sqs_queue.notification_queue.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "notification_sqs_policy_attachment" {
  role = "${aws_iam_role.notification_lambda_role.name}"
  policy_arn = "${aws_iam_policy.notification_sqs_policy.arn}"
}

/**
 * Lambda triggered every 5 minutes.
 *
 * @author Alibaba Cloud
 */

provider "aws" {
  region = "ap-south-1"
}

//
// Create the lambda.
//

resource "aws_iam_role" "timer_lambda_role" {
  name = "timer_lambda_role"

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

resource "aws_lambda_function" "timer_lambda" {
  filename = "target/timer.zip"
  function_name = "timer"
  role = "${aws_iam_role.timer_lambda_role.arn}"
  handler = "index.handler"
  source_code_hash = "${filebase64sha256("target/timer.zip")}"
  runtime = "nodejs8.10"
}

//
// Create the log group and attach the policy to the lambda.
//

resource "aws_cloudwatch_log_group" "timer_log_group" {
  name = "/aws/lambda/${aws_lambda_function.timer_lambda.function_name}"
  retention_in_days = 14
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_policy" "timer_logging_policy" {
  name = "timer_lambda_logging"
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
      "Resource": "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.timer_log_group.name}:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "timer_logging_policy_attachment" {
  role = "${aws_iam_role.timer_lambda_role.name}"
  policy_arn = "${aws_iam_policy.timer_logging_policy.arn}"
}


//
// Trigger the lambda every 5 minutes with a Cloudwatch event.
//

resource "aws_cloudwatch_event_rule" "timer_event_rule" {
  name = "timer_event_rule"
  description = "Fires every five minutes."
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "timer_event_target" {
  target_id = "timer_event_target"
  rule = "${aws_cloudwatch_event_rule.timer_event_rule.name}"
  arn = "${aws_lambda_function.timer_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.timer_lambda.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.timer_event_rule.arn}"
}
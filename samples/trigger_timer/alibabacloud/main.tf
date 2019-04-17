/**
 * Function triggered every 5 minutes.
 *
 * @author Alibaba Cloud
 */

provider "alicloud" {
  region = "ap-south-1"
}


//
// Create a log project and store.
//

resource "alicloud_log_project" "timer_log_project" {
  name = "timer-log-project"
}

resource "alicloud_log_store" "timer_log_store" {
  project = "${alicloud_log_project.timer_log_project.name}"
  name = "timer-log-store"
}


//
// Create a Function Compute service and configure it to use the log project created above.
//

resource "alicloud_ram_role" "timer_service_role" {
  name = "timer-service-role"
  services = [
    "fc.aliyuncs.com"
  ]
}

data "alicloud_regions" "current" {
  current = true
}

data "alicloud_account" "current" {}

resource "alicloud_ram_policy" "timer_service_policy" {
  name = "timer-service-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "log:PostLogStoreLogs"
      ]

      resource = [
        "acs:log:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:project/${alicloud_log_project.timer_log_project.name}/logstore/${alicloud_log_store.timer_log_store.name}",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "timer_policy_attachment" {
  policy_name = "${alicloud_ram_policy.timer_service_policy.name}"
  policy_type = "${alicloud_ram_policy.timer_service_policy.type}"
  role_name = "${alicloud_ram_role.timer_service_role.name}"
}

resource "alicloud_fc_service" "timer_service" {
  name = "timer_service"

  role = "${alicloud_ram_role.timer_service_role.arn}"

  log_config = {
    project = "${alicloud_log_project.timer_log_project.name}"
    logstore = "${alicloud_log_store.timer_log_store.name}"
  }

  depends_on = [
    "alicloud_ram_role_policy_attachment.timer_policy_attachment"
  ]
}


//
// Create the lambda function.
//

resource "alicloud_fc_function" "timer_function" {
  service = "${alicloud_fc_service.timer_service.name}"
  filename = "target/timer.zip"
  name = "timer"
  handler = "index.handler"
  runtime = "nodejs8"
}


//
// Trigger the function every 5 minutes.
//

resource "alicloud_fc_trigger" "timer_fc_trigger" {
  name = "timer-fc-trigger"
  service = "${alicloud_fc_service.timer_service.name}"
  function = "${alicloud_fc_function.timer_function.name}"
  type = "timer"

  config = <<EOF
    {
        "payload": "some-custom-payload",
        "cronExpression": "@every 5m",
        "enable": true
    }
  EOF
}

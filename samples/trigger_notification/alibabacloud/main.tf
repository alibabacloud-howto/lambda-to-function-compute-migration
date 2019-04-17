/**
 * Lambda triggered when a message is sent to a MNS topic.
 *
 * @author Alibaba Cloud
 */

provider "alicloud" {
  region = "ap-south-1"
}


//
// Create a log project and store.
//

resource "alicloud_log_project" "notification_log_project" {
  name = "notification-log-project"
}

resource "alicloud_log_store" "notification_log_store" {
  project = "${alicloud_log_project.notification_log_project.name}"
  name = "notification-log-store"
}


//
// Create a Function Compute service and configure it to use the log project created above.
//

resource "alicloud_ram_role" "notification_service_role" {
  name = "notification-service-role"
  services = [
    "fc.aliyuncs.com"
  ]
}

data "alicloud_regions" "current" {
  current = true
}

data "alicloud_account" "current" {}

resource "alicloud_ram_policy" "notification_service_policy" {
  name = "notification-service-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "log:PostLogStoreLogs"
      ]

      resource = [
        "acs:log:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:project/${alicloud_log_project.notification_log_project.name}/logstore/${alicloud_log_store.notification_log_store.name}",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "notification_policy_attachment" {
  policy_name = "${alicloud_ram_policy.notification_service_policy.name}"
  policy_type = "${alicloud_ram_policy.notification_service_policy.type}"
  role_name = "${alicloud_ram_role.notification_service_role.name}"
}

resource "alicloud_fc_service" "notification_service" {
  name = "notification_service"

  role = "${alicloud_ram_role.notification_service_role.arn}"

  log_config = {
    project = "${alicloud_log_project.notification_log_project.name}"
    logstore = "${alicloud_log_store.notification_log_store.name}"
  }

  depends_on = [
    "alicloud_ram_role_policy_attachment.notification_policy_attachment"
  ]
}


//
// Create the lambda function.
//

resource "alicloud_fc_function" "notification_function" {
  service = "${alicloud_fc_service.notification_service.name}"
  filename = "target/notification.zip"
  name = "notification"
  handler = "index.handler"
  runtime = "nodejs8"
}

//
// Create a MNS topic
//

resource "alicloud_mns_topic" "notification_mns_topic" {
  name = "notification-mns-topic"
}

//
// Trigger the function when a message is sent into the topic.
//

resource "alicloud_ram_role" "notification_trigger_ram_role" {
  name = "notification-trigger-ram-role"
  services = [
    "mns.aliyuncs.com"
  ]
}

resource "alicloud_ram_policy" "notification_trigger_ram_policy" {
  name = "notification-trigger-ram-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "fc:InvokeFunction"
      ]

      resource = [
        "acs:fc:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:services/${alicloud_fc_service.notification_service.name}/functions/*",
        "acs:fc:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:services/${alicloud_fc_service.notification_service.name}.*/functions/*"
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "notification_trigger_policy_attachment" {
  policy_name = "${alicloud_ram_policy.notification_trigger_ram_policy.name}"
  policy_type = "${alicloud_ram_policy.notification_trigger_ram_policy.type}"
  role_name = "${alicloud_ram_role.notification_trigger_ram_role.name}"
}

// Note: unfortunately "alicloud_fc_trigger" currently doesn't support MNS topics
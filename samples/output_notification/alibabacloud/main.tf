/**
 * Function that send a message into a MNS queue and a MNS topic.
 *
 * @author Alibaba Cloud
 */

provider "alicloud" {
  region = "ap-south-1"
}


//
// Create a log project and store, then allow the function to access it.
//

resource "alicloud_log_project" "outnotification_log_project" {
  name = "outnotification-log-project"
}

resource "alicloud_log_store" "outnotification_log_store" {
  project = "${alicloud_log_project.outnotification_log_project.name}"
  name = "outnotification-log-store"
}

resource "alicloud_ram_role" "outnotification_service_role" {
  name = "outnotification-service-role"
  services = [
    "fc.aliyuncs.com"
  ]
}

data "alicloud_regions" "current" {
  current = true
}

data "alicloud_account" "current" {}

resource "alicloud_ram_policy" "outnotification_service_policy" {
  name = "outnotification-service-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "log:PostLogStoreLogs"
      ]

      resource = [
        "acs:log:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:project/${alicloud_log_project.outnotification_log_project.name}/logstore/${alicloud_log_store.outnotification_log_store.name}",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "outnotification_policy_attachment" {
  policy_name = "${alicloud_ram_policy.outnotification_service_policy.name}"
  policy_type = "${alicloud_ram_policy.outnotification_service_policy.type}"
  role_name = "${alicloud_ram_role.outnotification_service_role.name}"
}


//
// Create a MNS topic and allow the function to send messages into it.
//

resource "alicloud_mns_topic" "outnotification_mns_topic" {
  name = "outnotification-mns-topic"
}

resource "alicloud_ram_policy" "outnotification_topic_policy" {
  name = "outnotification-topic-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "mns:PublishMessage"
      ]

      resource = [
        "acs:mns:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:/topics/${alicloud_mns_topic.outnotification_mns_topic.name}/messages",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "outnotification_topic_policy_attachment" {
  policy_name = "${alicloud_ram_policy.outnotification_topic_policy.name}"
  policy_type = "${alicloud_ram_policy.outnotification_topic_policy.type}"
  role_name = "${alicloud_ram_role.outnotification_service_role.name}"
}


//
// Create a MNS queue and allow the function to send messages into it.
//

resource "alicloud_mns_queue" "outnotification_mns_queue" {
  name = "outnotification-mns-queue"
}

resource "alicloud_ram_policy" "outnotification_queue_policy" {
  name = "outnotification-queue-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "mns:SendMessage"
      ]

      resource = [
        "acs:mns:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:/queues/${alicloud_mns_queue.outnotification_mns_queue.name}/messages",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "outnotification_queue_policy_attachment" {
  policy_name = "${alicloud_ram_policy.outnotification_queue_policy.name}"
  policy_type = "${alicloud_ram_policy.outnotification_queue_policy.type}"
  role_name = "${alicloud_ram_role.outnotification_service_role.name}"
}


//
// Create the service and the function.
//

resource "alicloud_fc_service" "outnotification_service" {
  name = "outnotification_service"

  role = "${alicloud_ram_role.outnotification_service_role.arn}"

  log_config = {
    project = "${alicloud_log_project.outnotification_log_project.name}"
    logstore = "${alicloud_log_store.outnotification_log_store.name}"
  }

  depends_on = [
    "alicloud_ram_role_policy_attachment.outnotification_policy_attachment",
    "alicloud_ram_role_policy_attachment.outnotification_topic_policy_attachment",
    "alicloud_ram_role_policy_attachment.outnotification_queue_policy_attachment"
  ]
}

resource "alicloud_fc_function" "outnotification_function" {
  service = "${alicloud_fc_service.outnotification_service.name}"
  filename = "target/output-notification.zip"
  name = "outnotification"
  handler = "index.handler"
  runtime = "nodejs8"

  environment_variables = {
    topicName = "${alicloud_mns_topic.outnotification_mns_topic.name}",
    queueName = "${alicloud_mns_queue.outnotification_mns_queue.name}"
  }
}

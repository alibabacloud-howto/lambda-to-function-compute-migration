/**
 * Basic function that just logs messages.
 *
 * @author Alibaba Cloud
 */

provider "alicloud" {
  region = "ap-south-1"
}


//
// Create a log project and store.
//

resource "alicloud_log_project" "basic_log_project" {
  name = "basic-log-project"
}

resource "alicloud_log_store" "basic_log_store" {
  project = "${alicloud_log_project.basic_log_project.name}"
  name = "basic-log-store"
}


//
// Create a Function Compute service and configure it to use the log project created above.
//

resource "alicloud_ram_role" "basic_service_role" {
  name = "basic-service-role"
  services = [
    "fc.aliyuncs.com"
  ]
}

data "alicloud_regions" "current" {
  current = true
}

data "alicloud_account" "current" {}

resource "alicloud_ram_policy" "basic_service_policy" {
  name = "basic-service-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "log:PostLogStoreLogs"
      ]

      resource = [
        "acs:log:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:project/${alicloud_log_project.basic_log_project.name}/logstore/${alicloud_log_store.basic_log_store.name}",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "basic_policy_attachment" {
  policy_name = "${alicloud_ram_policy.basic_service_policy.name}"
  policy_type = "${alicloud_ram_policy.basic_service_policy.type}"
  role_name = "${alicloud_ram_role.basic_service_role.name}"
}

resource "alicloud_fc_service" "basic_service" {
  name = "basic_service"

  role = "${alicloud_ram_role.basic_service_role.arn}"

  log_config = {
    project = "${alicloud_log_project.basic_log_project.name}"
    logstore = "${alicloud_log_store.basic_log_store.name}"
  }

  depends_on = [
    "alicloud_ram_role_policy_attachment.basic_policy_attachment"
  ]
}


//
// Create the function.
//

resource "alicloud_fc_function" "basic_function" {
  service = "${alicloud_fc_service.basic_service.name}"
  filename = "target/basic.zip"
  name = "basic"
  handler = "index.handler"
  runtime = "nodejs8"
}

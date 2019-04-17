/**
 * Function triggered when a file is created into a OSS bucket.
 *
 * @author Alibaba Cloud
 */

provider "alicloud" {
  region = "ap-south-1"
}


//
// Create a log project and store.
//

resource "alicloud_log_project" "storage_log_project" {
  name = "storage-log-project"
}

resource "alicloud_log_store" "storage_log_store" {
  project = "${alicloud_log_project.storage_log_project.name}"
  name = "storage-log-store"
}


//
// Create a Function Compute service and configure it to use the log project created above.
//

resource "alicloud_ram_role" "storage_service_role" {
  name = "storage-service-role"
  services = [
    "fc.aliyuncs.com"
  ]
}

data "alicloud_regions" "current" {
  current = true
}

data "alicloud_account" "current" {}

resource "alicloud_ram_policy" "storage_service_policy" {
  name = "storage-service-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "log:PostLogStoreLogs"
      ]

      resource = [
        "acs:log:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:project/${alicloud_log_project.storage_log_project.name}/logstore/${alicloud_log_store.storage_log_store.name}",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "storage_policy_attachment" {
  policy_name = "${alicloud_ram_policy.storage_service_policy.name}"
  policy_type = "${alicloud_ram_policy.storage_service_policy.type}"
  role_name = "${alicloud_ram_role.storage_service_role.name}"
}

resource "alicloud_fc_service" "storage_service" {
  name = "storage_service"

  role = "${alicloud_ram_role.storage_service_role.arn}"

  log_config = {
    project = "${alicloud_log_project.storage_log_project.name}"
    logstore = "${alicloud_log_store.storage_log_store.name}"
  }

  depends_on = [
    "alicloud_ram_role_policy_attachment.storage_policy_attachment"
  ]
}


//
// Create the lambda function.
//

resource "alicloud_fc_function" "storage_function" {
  service = "${alicloud_fc_service.storage_service.name}"
  filename = "target/object_storage.zip"
  name = "storage"
  handler = "index.handler"
  runtime = "nodejs8"
}

//
// Create a bucket
//

resource "alicloud_oss_bucket" "storage_bucket" {
  bucket = "storage-bucket-20190329"
}

//
// Trigger the function when an object is created in the bucket.
//

resource "alicloud_ram_role" "storage_trigger_ram_role" {
  name = "storage-trigger-ram-role"
  services = [
    "oss.aliyuncs.com"
  ]
}

resource "alicloud_ram_policy" "storage_trigger_ram_policy" {
  name = "storage-trigger-ram-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "fc:InvokeFunction"
      ]

      resource = [
        "acs:fc:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:services/${alicloud_fc_service.storage_service.name}/functions/*",
        "acs:fc:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:services/${alicloud_fc_service.storage_service.name}.*/functions/*"
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "storage_trigger_policy_attachment" {
  policy_name = "${alicloud_ram_policy.storage_trigger_ram_policy.name}"
  policy_type = "${alicloud_ram_policy.storage_trigger_ram_policy.type}"
  role_name = "${alicloud_ram_role.storage_trigger_ram_role.name}"
}

resource "alicloud_fc_trigger" "storage_fc_trigger" {
  name = "storage-fc-trigger"
  service = "${alicloud_fc_service.storage_service.name}"
  function = "${alicloud_fc_function.storage_function.name}"
  type = "oss"
  source_arn = "acs:oss:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:${alicloud_oss_bucket.storage_bucket.bucket}"
  role = "${alicloud_ram_role.storage_trigger_ram_role.arn}"

  config = <<EOF
    {
        "events": ["oss:ObjectCreated:*"]
    }
  EOF
}

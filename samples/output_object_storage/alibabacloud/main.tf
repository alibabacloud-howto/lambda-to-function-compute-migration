/**
 * Function that read and write a file on OSS.
 *
 * @author Alibaba Cloud
 */

provider "alicloud" {
  region = "ap-south-1"
}


//
// Create a log project and store, then allow the function to access it.
//

resource "alicloud_log_project" "outobjstorage_log_project" {
  name = "outobjstorage-log-project"
}

resource "alicloud_log_store" "outobjstorage_log_store" {
  project = "${alicloud_log_project.outobjstorage_log_project.name}"
  name = "outobjstorage-log-store"
}

resource "alicloud_ram_role" "outobjstorage_service_role" {
  name = "outobjstorage-service-role"
  services = [
    "fc.aliyuncs.com"
  ]
}

data "alicloud_regions" "current" {
  current = true
}

data "alicloud_account" "current" {}

resource "alicloud_ram_policy" "outobjstorage_service_policy" {
  name = "outobjstorage-service-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "log:PostLogStoreLogs"
      ]

      resource = [
        "acs:log:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:project/${alicloud_log_project.outobjstorage_log_project.name}/logstore/${alicloud_log_store.outobjstorage_log_store.name}",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "outobjstorage_policy_attachment" {
  policy_name = "${alicloud_ram_policy.outobjstorage_service_policy.name}"
  policy_type = "${alicloud_ram_policy.outobjstorage_service_policy.type}"
  role_name = "${alicloud_ram_role.outobjstorage_service_role.name}"
}


//
// Create an OSS bucket and allow the lambda to read and write on it.
//

resource "alicloud_oss_bucket" "outobjstorage_bucket" {
  bucket = "outobjstorage-bucket-20190402"
}

resource "alicloud_oss_bucket_object" "outobjstorage_bucket_object" {
  bucket = "${alicloud_oss_bucket.outobjstorage_bucket.bucket}"
  key = "test.txt"
  content = "sample-test-content"
}

resource "alicloud_ram_policy" "outobjstorage_bucket_policy" {
  name = "outobjstorage-bucket-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "oss:PutObject",
        "oss:GetObject"
      ]

      resource = [
        "acs:oss:oss-${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:${alicloud_oss_bucket.outobjstorage_bucket.bucket}/*",
      ]
    }
  ]
}

resource "alicloud_ram_role_policy_attachment" "outobjstorage_bucket_policy_attachment" {
  policy_name = "${alicloud_ram_policy.outobjstorage_bucket_policy.name}"
  policy_type = "${alicloud_ram_policy.outobjstorage_bucket_policy.type}"
  role_name = "${alicloud_ram_role.outobjstorage_service_role.name}"
}


//
// Create the service and the function.
//

resource "alicloud_fc_service" "outobjstorage_service" {
  name = "outobjstorage_service"

  role = "${alicloud_ram_role.outobjstorage_service_role.arn}"

  log_config = {
    project = "${alicloud_log_project.outobjstorage_log_project.name}"
    logstore = "${alicloud_log_store.outobjstorage_log_store.name}"
  }

  depends_on = [
    "alicloud_ram_role_policy_attachment.outobjstorage_policy_attachment",
    "alicloud_ram_role_policy_attachment.outobjstorage_bucket_policy_attachment"
  ]
}

resource "alicloud_fc_function" "outobjstorage_function" {
  service = "${alicloud_fc_service.outobjstorage_service.name}"
  filename = "target/output-object-storage.zip"
  name = "outobjstorage"
  handler = "index.handler"
  runtime = "nodejs8"

  environment_variables = {
    bucketName = "${alicloud_oss_bucket.outobjstorage_bucket.bucket}"
  }
}

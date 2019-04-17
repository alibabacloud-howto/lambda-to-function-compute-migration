/**
 * Infrastructure for the function and related cloud resources (OSS bucket, MNS queue, ...).
 *
 * @author Alibaba Cloud
 */

provider "alicloud" {
  region = "ap-south-1"
}

// OSS bucket
resource "alicloud_oss_bucket" "thumbnailer_bucket" {
  bucket = "thumbnailer-bucket-20190404"
}
resource "alicloud_oss_bucket_object" "thumbnailer_bucket_images_readme" {
  bucket = "${alicloud_oss_bucket.thumbnailer_bucket.bucket}"
  key = "images/README.TXT"
  content = "Upload images here."
}
resource "alicloud_oss_bucket_object" "thumbnailer_bucket_thumbnails_readme" {
  bucket = "${alicloud_oss_bucket.thumbnailer_bucket.bucket}"
  key = "thumbnails/README.TXT"
  content = "Upload thumbnails here."
}

// MNS queue
resource "alicloud_mns_queue" "thumbnailer_mns_queue" {
  name = "thumbnailer-mns-queue"
}

// Log project and store.
resource "alicloud_log_project" "thumbnailer_log_project" {
  name = "thumbnailer-log-project"
}
resource "alicloud_log_store" "thumbnailer_log_store" {
  project = "${alicloud_log_project.thumbnailer_log_project.name}"
  name = "thumbnailer-log-store"
}


// Role and permissions for the service
resource "alicloud_ram_role" "thumbnailer_service_role" {
  name = "thumbnailer-service-role"
  services = [
    "fc.aliyuncs.com"
  ]
}
data "alicloud_regions" "current" {
  current = true
}
data "alicloud_account" "current" {}
resource "alicloud_ram_policy" "thumbnailer_policy" {
  name = "thumbnailer-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "log:PostLogStoreLogs"
      ]

      resource = [
        "acs:log:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:project/${alicloud_log_project.thumbnailer_log_project.name}/logstore/${alicloud_log_store.thumbnailer_log_store.name}",
      ]
    },
    {
      effect = "Allow"
      action = [
        "oss:PutObject",
        "oss:GetObject"
      ]

      resource = [
        "acs:oss:oss-${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:${alicloud_oss_bucket.thumbnailer_bucket.bucket}/*",
      ]
    },
    {
      effect = "Allow"
      action = [
        "mns:SendMessage"
      ]

      resource = [
        "acs:mns:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:/queues/${alicloud_mns_queue.thumbnailer_mns_queue.name}/messages",
      ]
    }
  ]
}
resource "alicloud_ram_role_policy_attachment" "thumbnailer_policy_attachment" {
  policy_name = "${alicloud_ram_policy.thumbnailer_policy.name}"
  policy_type = "${alicloud_ram_policy.thumbnailer_policy.type}"
  role_name = "${alicloud_ram_role.thumbnailer_service_role.name}"
}

// Service
resource "alicloud_fc_service" "thumbnailer_service" {
  name = "thumbnailer-service"

  role = "${alicloud_ram_role.thumbnailer_service_role.arn}"

  log_config = {
    project = "${alicloud_log_project.thumbnailer_log_project.name}"
    logstore = "${alicloud_log_store.thumbnailer_log_store.name}"
  }

  depends_on = [
    "alicloud_ram_role_policy_attachment.thumbnailer_policy_attachment"
  ]
}


// Function
resource "alicloud_fc_function" "thumbnailer_function" {
  service = "${alicloud_fc_service.thumbnailer_service.name}"
  filename = "../target/thumbnailer.zip"
  name = "thumbnailer"
  handler = "indexalibabacloud.handler"
  runtime = "nodejs8"
  timeout = 30

  environment_variables = {
    queueName = "${alicloud_mns_queue.thumbnailer_mns_queue.name}"
  }
}


// OSS trigger role
resource "alicloud_ram_role" "thumbnailer_trigger_ram_role" {
  name = "thumbnailer-trigger-ram-role"
  services = [
    "oss.aliyuncs.com"
  ]
}
resource "alicloud_ram_policy" "thumbnailer_trigger_ram_policy" {
  name = "thumbnailer-trigger-ram-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "fc:InvokeFunction"
      ]

      resource = [
        "acs:fc:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:services/${alicloud_fc_service.thumbnailer_service.name}/functions/*",
        "acs:fc:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:services/${alicloud_fc_service.thumbnailer_service.name}.*/functions/*"
      ]
    }
  ]
}
resource "alicloud_ram_role_policy_attachment" "thumbnailer_trigger_policy_attachment" {
  policy_name = "${alicloud_ram_policy.thumbnailer_trigger_ram_policy.name}"
  policy_type = "${alicloud_ram_policy.thumbnailer_trigger_ram_policy.type}"
  role_name = "${alicloud_ram_role.thumbnailer_trigger_ram_role.name}"
}


// OSS trigger
resource "alicloud_fc_trigger" "thumbnailer_fc_trigger" {
  name = "thumbnailer-fc-trigger"
  service = "${alicloud_fc_service.thumbnailer_service.name}"
  function = "${alicloud_fc_function.thumbnailer_function.name}"
  type = "oss"
  source_arn = "acs:oss:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:${alicloud_oss_bucket.thumbnailer_bucket.bucket}"
  role = "${alicloud_ram_role.thumbnailer_trigger_ram_role.arn}"

  config = <<EOF
    {
        "events": ["oss:ObjectCreated:*"],
        "filter": {
            "key": {
                "prefix": "images/"
            }
        }
    }
  EOF

  depends_on = [
    "alicloud_ram_role_policy_attachment.thumbnailer_trigger_policy_attachment"
  ]
}
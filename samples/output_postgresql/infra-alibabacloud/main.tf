/**
 * Infrastructure for the database, function and related resources.
 *
 * @author Alibaba Cloud
 */

provider "alicloud" {
  region = "ap-south-1"
}

// VPC and Vswitch
resource "alicloud_vpc" "outpg_vpc" {
  name = "outpg-vpc"
  cidr_block = "192.168.0.0/16"
}
data "alicloud_zones" "current" {
  available_resource_creation = "Rds"
}
resource "alicloud_vswitch" "outpg_vswitch" {
  name = "outpg-vswitch"
  vpc_id = "${alicloud_vpc.outpg_vpc.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "${data.alicloud_zones.current.zones.0.id}"
}

// Database
resource "alicloud_db_instance" "outpg_db_instance" {
  instance_name = "outpg-db-instance"
  engine = "PostgreSQL"
  engine_version = "9.4"
  instance_type = "rds.pg.t1.small"
  instance_storage = 5
  vswitch_id = "${alicloud_vswitch.outpg_vswitch.id}"

  security_ips = [
    "${alicloud_vpc.outpg_vpc.cidr_block}"
  ]
}

// Log project and store.
resource "alicloud_log_project" "outpg_log_project" {
  name = "outpg-log-project"
}
resource "alicloud_log_store" "outpg_log_store" {
  project = "${alicloud_log_project.outpg_log_project.name}"
  name = "outpg-log-store"
}

// Role and permissions for the service
resource "alicloud_ram_role" "outpg_service_role" {
  name = "outpg-service-role"
  services = [
    "fc.aliyuncs.com"
  ]
}
data "alicloud_regions" "current" {
  current = true
}
data "alicloud_account" "current" {}
resource "alicloud_ram_policy" "outpg_policy" {
  name = "outpg-policy"

  statement = [
    {
      effect = "Allow"
      action = [
        "log:PostLogStoreLogs"
      ]

      resource = [
        "acs:log:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:project/${alicloud_log_project.outpg_log_project.name}/logstore/${alicloud_log_store.outpg_log_store.name}",
      ]
    },
    {
      effect = "Allow"
      action = [
        "vpc:DescribeVSwitchAttributes"
      ]

      resource = [
        "acs:vpc:${data.alicloud_regions.current.regions.0.id}:${data.alicloud_account.current.id}:vswitch/${alicloud_vswitch.outpg_vswitch.id}",
      ]
    },
    {
      effect = "Allow"
      action = [
        "ecs:CreateNetworkInterface",
        "ecs:DeleteNetworkInterface",
        "ecs:DescribeNetworkInterfaces",
        "ecs:CreateNetworkInterfacePermission",
        "ecs:DescribeNetworkInterfacePermissions",
        "ecs:DeleteNetworkInterfacePermission"
      ],
      resource = [
        "*"
      ]
    }
  ]
}
resource "alicloud_ram_role_policy_attachment" "outpg_policy_attachment" {
  policy_name = "${alicloud_ram_policy.outpg_policy.name}"
  policy_type = "${alicloud_ram_policy.outpg_policy.type}"
  role_name = "${alicloud_ram_role.outpg_service_role.name}"
}

// Security group
resource "alicloud_security_group" "outpg_security_group" {
  name = "outpg-security-group"
  vpc_id = "${alicloud_vpc.outpg_vpc.id}"
}

// Service
resource "alicloud_fc_service" "outpg_service" {
  name = "outpg-service"

  role = "${alicloud_ram_role.outpg_service_role.arn}"

  log_config = {
    project = "${alicloud_log_project.outpg_log_project.name}"
    logstore = "${alicloud_log_store.outpg_log_store.name}"
  }

  vpc_config = {
    vswitch_ids = [
      "${alicloud_vswitch.outpg_vswitch.id}"
    ],
    security_group_id = "${alicloud_security_group.outpg_security_group.id}"
  }

  depends_on = [
    "alicloud_ram_role_policy_attachment.outpg_policy_attachment"
  ]
}

// Function
resource "alicloud_fc_function" "outpg_function" {
  service = "${alicloud_fc_service.outpg_service.name}"
  filename = "../target/outpg.zip"
  name = "outpg"
  handler = "index.handler"
  runtime = "nodejs8"
  timeout = 30

  environment_variables = {
    host = "${alicloud_db_instance.outpg_db_instance.connection_string}",
    port = "${alicloud_db_instance.outpg_db_instance.port}",
    database = "${var.db_name}",
    username = "${var.db_user}",
    password = "${var.db_password}"
  }
}

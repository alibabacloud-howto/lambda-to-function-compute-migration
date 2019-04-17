/**
 * Output values.
 *
 * @author Alibaba Cloud
 */

output "db_instance_id" {
  value = "${alicloud_db_instance.outpg_db_instance.id}"
}
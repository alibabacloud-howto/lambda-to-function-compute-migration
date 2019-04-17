/**
 * Output values.
 *
 * @author Alibaba Cloud
 */

output "db_instance_id" {
  value = "${aws_db_instance.outpg_db_instance.id}"
}

output "vpc_id" {
  value = "${aws_vpc.outpg_vpc.id}"
}
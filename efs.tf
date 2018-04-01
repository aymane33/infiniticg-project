resource "aws_efs_file_system" "web-content" {
  creation_token = "infiniticg-web-content"
  encrypted = true
  depends_on = ["aws_security_group.web-ec2"]
  tags {
    Name = "infiniticg-web-content"
  }

}
resource "aws_efs_mount_target" "web-content-mount" {
  file_system_id = "${aws_efs_file_system.web-content.id}"
  subnet_id = "${element(var.private-subnet-list-ids,1)}"
  security_groups = ["${aws_security_group.efs.id}"]
  count = 2
  subnet_id = "${element(var.private-subnet-list-ids, count.index)}"
}

output "web-content-dns" {
  value = "${aws_efs_mount_target.web-content-mount.*.dns_name}"
}

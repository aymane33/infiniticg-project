//1. Define ELB . output ELB DNS
//2. Define ASG.  Use Place Holder AMI.
//3. Add ASG to ELB

resource "aws_elb" "web-elb" {
  "listener" {
    instance_port = 443
    instance_protocol = "tcp"
    lb_port = 443
    lb_protocol = "tcp"
    //ssl_certificate_id = "${var.sslCertificate}"
  }
  //for testing
  "listener" {
    instance_port = 22
    instance_protocol = "tcp"
    lb_port = 22
    lb_protocol = "tcp"
    //ssl_certificate_id = "${var.sslCertificate}"
  }
  "listener" {
    instance_port = 80
    instance_protocol = "tcp"
    lb_port = 80
    lb_protocol = "tcp"
    //ssl_certificate_id = "${var.sslCertificate}"
  }
  idle_timeout = "300"
  cross_zone_load_balancing = true
  subnets = ["${element(var.public-subnet-list-ids,0)}","${element(var.public-subnet-list-ids,1)}"]
  name = "web-elb"
  internal = false
  security_groups = ["${aws_security_group.web-elb.id}"]

health_check {
  healthy_threshold = 2
  interval = 60
  target = "TCP:80"   //comeback..check HTTPS..infiniticg
  timeout = 30
  unhealthy_threshold = 10
}
}
output "web-elb-dns-name" {
  value = "${aws_elb.web-elb.dns_name}"
}
//
resource "aws_security_group" "web-elb" {
  vpc_id = "${var.vpc-id}"
  name = "web-elb-security-group"
  ingress {
    from_port = 80
    protocol = "tcp"//check using ssl/https instead.  comeback
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]//come back.. limit to apigateway
  }
  ingress {
    from_port = 443
    protocol = "tcp"//check using ssl/https instead.  comeback
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]//come back.. limit to apigateway
  }
  ingress { //open port 22 for testing only
    from_port = 22
    protocol = "tcp"//check using ssl/https instead.  comeback
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]//come back.. limit to apigateway
  }
  egress {
    from_port = 0
    protocol = "tcp"//check using tcp instead.  comeback
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}
//

//Define ASG
resource "aws_security_group" "web-ec2" {
  vpc_id = "${var.vpc-id}"
  name = "web-security-group"
  ingress {
    from_port = 0
    protocol = "tcp"//check using tcp instead.  comeback
    to_port = 65535
    //cidr_blocks = ["0.0.0.0./0"] // restrict to elb only
    security_groups = ["${aws_security_group.web-elb.id}"]
  }
  egress {
    from_port = 0
    protocol = "tcp"//check using tcp instead.  comeback
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}
//nfs4
resource "aws_security_group" "efs" {
  vpc_id = "${var.vpc-id}"
  name = "efs-security-group"
  ingress {
    from_port = 0
    protocol = "tcp"//check using tcp instead.  comeback
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"] // restrict to elb only
    //security_groups = ["${aws_security_group.web-elb.id}"]
  }
  ingress {
    from_port = 0
    protocol = "udp"//check using tcp instead.  comeback
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"] // restrict to elb only
    //security_groups = ["${aws_security_group.web-elb.id}"]
  }
  egress {
    from_port = 0
    protocol = "tcp"//check using tcp instead.  comeback
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "udp"//check using tcp instead.  comeback
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_launch_configuration" "web-launch-group" {
  name = "web-launch-group"
  depends_on = ["aws_security_group.web-ec2","aws_efs_file_system.web-content"]
  image_id = "${var.ec2AMI}"//comeback,
  instance_type = "t2.micro" 
  key_name = "${var.sshKey}"
  enable_monitoring = true 
  user_data = "#!/bin/bash\nsudo yum install -y nfs-utils\nsudo mkdir ~/web-content\nsudo mount -t nfs ${aws_efs_file_system.web-content.dns_name}:/ ~/web-content\nsudo yum install -y httpd\nsudo sed -i 's/^DocumentRoot .*/DocumentRoot ~/web-content/' /etc/httpd/conf/httpd.conf\nsystemctl start httpd\nsudo touch ~/web-content/index.html\nsudo chmod 744 ~/web-content/*\nsudo echo 'To InfinitiCG and Beyound'>~/web-content/index.html"
  security_groups = ["${aws_security_group.web-ec2.id}"]
}

resource "aws_autoscaling_group" "web-asg" {
  depends_on = ["aws_launch_configuration.web-launch-group"]
  name = "web-asg"
  launch_configuration = "${aws_launch_configuration.web-launch-group.id}"
  max_size = 1 //hardcoded for now. comeback
  min_size = 1 //hardcoded for now. comeback
  load_balancers = ["${aws_elb.web-elb.id}"]
  default_cooldown = 300
  vpc_zone_identifier = ["${element(var.private-subnet-list-ids,0)}","${element(var.private-subnet-list-ids,1)}"]
  desired_capacity = 1 //comeback
  health_check_grace_period = 300
  health_check_type = "ELB"


  tag {
    key = "nextgen:costcenter"
    propagate_at_launch = false
    value = "Devops"
  }
}

resource "aws_autoscaling_policy" "ec2-up" {
  name                   = "ec2 Scale Up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"

}
resource "aws_autoscaling_policy" "ec2-down" {
  name                   = "ec2 Scale Down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
}
//Define mertics/alerts and link that to asg
resource "aws_cloudwatch_metric_alarm" "cpu-util-up" {
  alarm_name          = "$cpu-util-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web-asg.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.ec2-up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "cpu-util-down" {
  alarm_name          = "cpu-util-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web-asg.name}"
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = ["${aws_autoscaling_policy.ec2-down.arn}"]
}




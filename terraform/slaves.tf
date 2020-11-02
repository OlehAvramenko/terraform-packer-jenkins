resource "aws_launch_configuration" "jenkins_worker_linux" {
  name_prefix                 = "${var.main_name}-jenkins-workers"
  image_id                    = "${data.aws_ami.ubuntu.image_id}"
  instance_type               = "${var.instance_type_worker}"
  iam_instance_profile        = "${aws_iam_instance_profile.profile.name}"
  key_name                    = "${var.keyname}"
  security_groups = [aws_security_group.allow_ssh_jenkins-demo5.id]
  user_data                   = "${data.template_file.userdata_jenkins_worker_linux.rendered}"
  associate_public_ip_address = true


  root_block_device {
    delete_on_termination = true
    volume_size = 20
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "jenkins_worker_linux" {
  name                      = "${var.main_name}-Jenkins-worker"
  min_size                  = "${var.min_size_scale_group}"
  max_size                  = "${var.max_size_scale_group}"
  desired_capacity          = "${var.desired_capacity_scale_group}"
  health_check_grace_period = 60
  health_check_type         = "EC2"
  vpc_zone_identifier       = ["${aws_subnet.public-subnet-1.id}"]
  launch_configuration      = "${aws_launch_configuration.jenkins_worker_linux.name}"
  termination_policies      = ["OldestLaunchConfiguration"]
  wait_for_capacity_timeout = "10m"
  default_cooldown          = 60

  tags = [
    {
      key                 = "Name"
      value               = "${var.main_name}-Jenkins-worker"
      propagate_at_launch = true
    },
  ]
}

# ---------------------- rules for scale -----------------------

resource "aws_autoscaling_policy" "agents-scale-up" {
    name = "${var.main_name}-agents-scale-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 240
    autoscaling_group_name = "${aws_autoscaling_group.jenkins_worker_linux.name}"
}

resource "aws_autoscaling_policy" "agents-scale-down" {
    name = "${var.main_name}-agents-scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.jenkins_worker_linux.name}"
}

resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "${var.main_name}-mem-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    # number of periods
    evaluation_periods = "1"
    metric_name = "MemoryUtilization"
    namespace = "AWS/EC2"
    period = "240"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.agents-scale-up.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.jenkins_worker_linux.name}"
    }
}

resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "${var.main_name}-mem-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "1"
    metric_name = "MemoryUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "40"
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.agents-scale-down.arn}"
    ]
    dimensions = {
        AutoScalingGroupName = "${aws_autoscaling_group.jenkins_worker_linux.name}"
    }
}

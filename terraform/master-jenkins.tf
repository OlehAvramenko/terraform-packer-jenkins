resource "aws_instance" "jenkins-instance" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "${var.instance_type_master}"
  key_name        = "${var.keyname}"
  #vpc_id          = "${aws_vpc.development-vpc.id}"
  vpc_security_group_ids = [aws_security_group.allow_ssh_jenkins-demo5.id]
  subnet_id          = "${aws_subnet.public-subnet-1.id}"
  iam_instance_profile = "${aws_iam_instance_profile.profile.name}"
  user_data = "${data.template_file.userdata_jenkins.rendered}"
  associate_public_ip_address = true

  tags = {
    Name = "${var.main_name}-jenkins"
  }
}

resource "aws_security_group" "allow_ssh_jenkins-demo5" {
  name        = "${var.main_name}-Jenkins"
  description = "Allow SSH and Jenkins inbound traffic"
  vpc_id      = "${aws_vpc.vpc_for_demo5.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 33453
    to_port     = 33453
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

output "jenkins_ip_address" {
  value = aws_instance.jenkins-instance.public_dns
}

# ------------------- custom AMI for instances ----------------------
data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["DEMO5-Jenkins-master-and-slave*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
        owners = ["self"]
}
# ----------------------- template for master -----------------------
data "template_file" "userdata_jenkins" {
  template = "${file("scripts/jenkins_master.sh")}"

  vars = {
    JENKINS_ADMIN_PASSWORD = "${var.JENKINS_ADMIN_PASSWORD}"
    JENKINS_USER_PASSWORD = "${var.JENKINS_USER_PASSWORD}"
    GITLAB_TOKEN = "${var.GITLAB_TOKEN}"
    SECRET_TOKEN = "${var.SECRET_TOKEN}"
    PROJECT_ID = "21643490"
    JOB_NAME = "pipeline-spring"
    REPO= "https://github.com/OlehAvramenko/manifest.git"
    SLAVE_PORT = "33453"
  }
}

# --------------------- template for workers -------------------------
data "template_file" "userdata_jenkins_worker_linux" {
  template = "${file("scripts/jenkins_worker.sh")}"

  vars = {
    node_name   = "jenkins-worker"
    device_name = "eth0"
    worker_pem = "${data.local_file.jenkins_pem.content}"
    server_ip   = "${aws_instance.jenkins-instance.private_ip}"
    jenkins_username = "admin"
    jenkins_password = "${var.JENKINS_ADMIN_PASSWORD}"
    NUMBER_OF_EXECUTORS = "2"
    PORT_SSH = "22"
    LABEL = "build"

  }
}

# ------------------- key for instances ---------------------------------
data "local_file" "jenkins_pem" {
  filename = "instance-key/demo-jenkins-instance.pem"
}

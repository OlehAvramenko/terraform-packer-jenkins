variable "region" {
  default = "us-east-1"
}

variable "keyname" {
  default = "demo-jenkins-instance"
}

variable "main_name" {
  default = "Demo5"
}

variable "instance_type_master" {
  default = "t2.small"
}

variable "instance_type_worker" {
  default = "t2.small"
}

# ------------------------------ PARAMS SCALE GROUP  -----------------------------

variable "max_size_scale_group" {
  default = "2"
}

variable "min_size_scale_group" {
  default = "1"
}

variable "desired_capacity_scale_group" {
  default = "1"
}

# --------------------------------- VPC --------------------------------

variable "vpc_cidr" {
  default = "10.10.10.0/24"
}

variable "public_subnet_1_cidr" {
  default = "10.10.10.0/25"
}

# -------------------------------- CREDENTIALS ------------------------------------
variable "JENKINS_ADMIN_PASSWORD" {
  type        = string
  description = "Set Jenkins admin password"
}

variable "JENKINS_USER_PASSWORD" {
  type        = string
  description = "Set Jenkins user password"
}

variable "GITLAB_TOKEN" {
  type        = string
  description = "Set GitLab access token"
}

variable "SECRET_TOKEN" {
  type        = string
  description = "Set GitLab secret token for webhook"
}

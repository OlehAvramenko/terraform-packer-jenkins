# ---------------------- Create VPC -----------------------
resource "aws_vpc" "vpc_for_demo5" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.main_name}-jenkins_VPC"
  }
}
# --------------------- Create subnet -------------------------
resource "aws_subnet" "public-subnet-1" {
  cidr_block        = var.public_subnet_1_cidr
  vpc_id            = "${aws_vpc.vpc_for_demo5.id}"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.main_name}-jenkins_Public-Subnet-1"
  }
}

# ------------------------- Create route table ----------------------
resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.vpc_for_demo5.id}"
  tags = {
    Name = "${var.main_name}-jenkins-Public-RouteTable"
  }
}

# ------------------------ Bind subnet to route table -------------------------
resource "aws_route_table_association" "public-route-1-association" {
  route_table_id = "${aws_route_table.public-route-table.id}"
  subnet_id      = "${aws_subnet.public-subnet-1.id}"
}

  # ---------------------- Create GW --------------------------
resource "aws_internet_gateway" "demo5-gw" {
  vpc_id = "${aws_vpc.vpc_for_demo5.id}"

  tags = {
    Name = "${var.main_name}-jenkins-gate"
  }
}
# -------------------------- Create route for GW -----------------------
resource "aws_route" "route" {
  route_table_id            = "${aws_route_table.public-route-table.id}"
  gateway_id                = "${aws_internet_gateway.demo5-gw.id}"
  destination_cidr_block    = "0.0.0.0/0"
}

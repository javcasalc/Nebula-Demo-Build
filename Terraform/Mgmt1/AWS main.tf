variable "modulename" {}
variable "public_first_three_octets" {}
variable "private_first_three_octets" {}
variable "myip" {}
variable "ami_ubuntu1804" {}
variable "ami_centos8" {}
variable "ami_win2019" {}
variable "admin_password" {}
variable "key" {}

resource "aws_key_pair" "service" {
  key_name = "${var.modulename} Service"
  public_key = "${var.key}"
}

resource "aws_vpc" "VPC" {
  cidr_block  = "${var.public_first_three_octets}.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "n${var.modulename}"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "private_cidr" {
  vpc_id     = "${aws_vpc.VPC.id}"
  cidr_block = "${var.private_first_three_octets}.0/24"
}

resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = "${aws_vpc.VPC.id}"
  tags = {
    Name = "g${var.modulename}"
  }
}

resource "aws_security_group" "ServiceSG" {
  name = "ServiceSG"
  description = "Service security group"
  vpc_id = "${aws_vpc.VPC.id}"

  tags = {
    Name = "ServiceSG"
  }

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "CommonManagementSG" {
  name = "CommonManagementSG"
  description = "Common Management security group"
  vpc_id = "${aws_vpc.VPC.id}"

  tags = {
    Name = "CommonManagementSG"
  }
}

resource "aws_security_group_rule" "CommonManagementSG_ICMP_From_MyIP" {
  type = "ingress"  
  protocol = "icmp"
  from_port = -1
  to_port = -1
  cidr_blocks = ["${var.myip}"]
  security_group_id = "${aws_security_group.CommonManagementSG.id}"
}

resource "aws_security_group_rule" "CommonManagementSG_SSH_From_MyIP" {
  type = "ingress"  
  protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_blocks = ["${var.myip}"]
  security_group_id = "${aws_security_group.CommonManagementSG.id}"
}

resource "aws_security_group_rule" "CommonManagementSG_SSH_From_AWX_Public_IP" {
  type = "ingress"  
  protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_blocks = ["${aws_eip.awx.public_ip}/32"]
  security_group_id = "${aws_security_group.CommonManagementSG.id}"
}

resource "aws_security_group_rule" "CommonManagementSG_SSH_From_AWX_Private_IP" {
  type = "ingress"  
  protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_blocks = ["${aws_instance.awx.private_ip}/32"]
  security_group_id = "${aws_security_group.CommonManagementSG.id}"
}

resource "aws_security_group_rule" "CommonManagementSG_Ingress_Nebula" {
  type = "ingress"  
  protocol = "udp"
  from_port = 4242
  to_port = 4242
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.CommonManagementSG.id}"
}

resource "aws_security_group_rule" "CommonManagementSG_Egress_Nebula" {
  type = "egress"  
  protocol = "udp"
  from_port = 4242
  to_port = 4242
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.CommonManagementSG.id}"
}
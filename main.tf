data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com/"
}

locals {
  my_ip = chomp(data.http.my_ip.response_body)
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] 

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_vpc" "portfolio_vpc" {
    cidr_block           = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true

}

resource "aws_subnet" "portfolio_subnet" {
    vpc_id = aws_vpc.portfolio_vpc.id
    cidr_block = var.subnet_cidr
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "portfolio_internet_gateway" {
    vpc_id = aws_vpc.portfolio_vpc.id
  
}

resource "aws_route_table" "portfolio_route_table" {
    vpc_id = aws_vpc.portfolio_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.portfolio_internet_gateway.id
    }
}

resource "aws_route_table_association" "igw" {
    route_table_id = aws_route_table.portfolio_route_table.id
    subnet_id = aws_subnet.portfolio_subnet.id

}


resource "tls_private_key" "portfolio" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "portfolio" {
  key_name   = "portfolio-key"
  public_key = tls_private_key.portfolio.public_key_openssh
}


resource "local_sensitive_file" "pem" {
  content         = tls_private_key.portfolio.private_key_pem
  filename        = "${path.module}/portfolio.pem"
  file_permission = "0600"
}

resource "aws_security_group" "portfolio_security_group" {
  name        = "portfolio_security_group"
  description = "Security group for portfolio"
  vpc_id      = aws_vpc.portfolio_vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]
  }


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "portfolio_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.portfolio_subnet.id
  key_name                    = aws_key_pair.portfolio.key_name
  associate_public_ip_address = true
  vpc_security_group_ids     = [aws_security_group.portfolio_security_group.id]


  provisioner "file" {
    source      = "${path.module}/install.sh"
    destination = "/home/ubuntu/install.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.portfolio.private_key_pem
      host        = self.public_ip
    }
  }


  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/install.sh",
      "sudo /home/ubuntu/install.sh",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.portfolio.private_key_pem
      host        = self.public_ip
    }
  }


  depends_on = [local_sensitive_file.pem]
}


variable "subnet_prefix" {
  // can have any of the attributes: "description", "default", or "type"
  description = "cidr block for the subnet"
  default = "10.0.66.0/24"
}

# 1. create vpc

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prod-vpc"
  }
}

# 2. create internet gateway

resource "aws_internet_gateway" "aws-igt" {
  vpc_id = aws_vpc.prod-vpc.id
}

# 3. create custom route table

resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    // default route
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws-igt.id
  }

#   IPV6
#   route {
#     ipv6_cidr_block        = "::/0"
#     egress_only_gateway_id = aws_internet_gateway.aws-igt.id
#   }

  tags = {
    Name = "prod-rt"
  }
}

# 4. create a subnet

resource "aws_subnet" "prod-subnet1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "ca-central-1a"
  tags = {
    #   Name = "prod-subnet1"
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "prod-subnet2" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[1].cidr_block
  availability_zone = "ca-central-1b"
  tags = {
    #   Name = "prod-subnet2"
    Name = var.subnet_prefix[1].name
  }
}


# 5. Associate subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet1.id
  route_table_id = aws_route_table.prod-rt.id
}

# 6. create security group to allow port 22, 80, 443

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic and all outbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  tags = {
    Name = "allow_web"
  }

  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
    from_port = 0
    to_port = 0
    protocol = "-1" # semantically equivalent to all ports
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 7. create a network interface with an ip address in the subnet in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.prod-subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

# 8. assign an elastic IP to the network interface created in step 7

resource "aws_epi" "one" {
  vpc = true
  network_interface = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.aws-igt ] // passing as a list
}

# 9. create ubuntu server an install/enable apache

# --> see ec2-instance.tf filr

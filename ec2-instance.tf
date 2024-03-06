resource "aws_instance" "web-server" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = "ca-central-1a"
  key_name = "nok"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install apache2 -y
    sudo systemctl enable apache2
    sudo systemctl start apache2
    echo "<h1>Hello, World!</h1>" | sudo tee /var/www/html/index.html
    # sudo bash -c "echo your very first web server >  /var/www/html/index.html"
    EOF

  tags = {
    Name = "web-server"
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
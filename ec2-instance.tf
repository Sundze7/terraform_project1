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
    sudo tee /var/www/html/index.html << INNER_BOB
    <h1>Hello, World!. Terraform sweet</h1>
    <h2> How much are you willing to learn and grow </h2>
    <h3> DEVOPS can make you RIIIICHHHHHH </h3>
    INNER_BOB
    # echo "<h1>Hello, World!. Terraform sweet</h1>" | sudo tee /var/www/html/index.html
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

output "web_server_id" {
  value = aws_instance.web-server.id
}
output "server_private_ip" {
  value = aws_instance.web-server.private_ip
}

output "server_prublic_ip" {
  value = aws_instance.web-server.public_ip
}
resource "tls_private_key" "tfkey" {
  algorithm = "RSA"
}
resource "local_file" "myterrakey" {
  content = tls_private_key.tfkey.private_key_pem
  filename = "myterrakey.pem"
}

resource "aws_key_pair" "terrakey" {
  key_name = "myterrakey"
  public_key = tls_private_key.tfkey.public_key_openssh
}


resource "aws_security_group" "allow_my_22" {
  name = "allow_ssh"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "myinst" {
  ami = "ami-0c38b9e37c107d921"
  instance_type = "t2.micro"
  key_name = aws_key_pair.terrakey.key_name
  vpc_security_group_ids = [aws_security_group.allow_my_22.id]

provisioner "local-exec" {
  command = "echo The server ip iddress is ${self.public_ip} > ip.yml"
}
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = tls_private_key.tfkey.private_key_pem
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
        "echo ${self.private_ip} >> /home/ec2-user/private.ips.txt",
        "sudo yum install nginx -y",
        "sudo systemctl start nginx"
     ]
  }
}

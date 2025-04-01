provider "aws" {
  #profile = "default"
  access_key = "keyhere"
  secret_key = "key-here"
  region     = "us-east-1"
}


##################################################################################

#This uses the default VPC.  It WILL NOT delete it on destroy.
resource "aws_default_vpc" "default" {

}

variable "ingressrules" {
  type    = list(number)
  default = [80, 443, 22]
}

resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "Allow ssh and standard http/https ports inbound and everything outbound"

  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" = "true"
  }
}

data "aws_ami" "amzlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]

}

resource "aws_instance" "datadog-2" {
  count           = 1
  ami             = data.aws_ami.amzlinux.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "datadog2"


  provisioner "file" {
    source      = "scriptubuntu.sh"
    destination = "/home/ec2-user/scriptubuntu.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod u+x /home/ec2-user/scriptubuntu.sh",
      "sudo /home/ec2-user/scriptubuntu.sh",
    ]
  }



  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("/Users//git/infra/terra/datadog/datadog2.pem")
  }


  tags = {
    "Name"      = "ubuntu1"
    "Terraform" = "true"
  }
}


#resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
#     alarm_name               = "cpu-utilization"
#     comparison_operator       = "GreaterThanOrEqualToThreshold"
#     evaluation_periods       = "2"
#     metric_name               = "CPUUtilization"
#     namespace                 = "AWS/EC2"
#     period                   = "120" #seconds
#     statistic                 = "Average"
#     threshold                 = "80"
#   alarm_description         = "This metric monitors ec2 cpu utilization"
#     insufficient_data_actions = []
#
#dimensions = {
#
#       InstanceId = aws_instance.datadog2.id
#
#     }
#}


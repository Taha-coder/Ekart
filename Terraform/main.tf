# Specify the provider and region
provider "aws" {
  region = "us-west-2"  # Change to your desired AWS region
}

# Define the key pair for the instances (replace with your key pair name)
variable "key_name" {
  default = "your-key-pair"  # Replace with your actual key pair name
}

# Define the existing security group (replace with your actual security group ID)
variable "security_group_id" {
  default = "sg-0123456789abcdef0"  # Replace with your existing security group ID
}

# Define the EC2 instances
resource "aws_instance" "sonarqube" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with your desired AMI ID
  instance_type = "t2.micro"  # Change as needed
  key_name      = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "sonarqube"
  }
}

resource "aws_instance" "nexus" {
  ami           = "ami-0c55b159cbfafe1f0"  # Replace with your desired AMI ID
  instance_type = "t2.micro"  # Change as needed
  key_name      = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "nexus"
  }
}

# Define the EBS volumes
resource "aws_ebs_volume" "sonarqube_volume" {
  availability_zone = aws_instance.sonarqube.availability_zone
  size              = 15  # Size in GB
  type              = "gp2"  # General Purpose SSD

  tags = {
    Name = "sonarqube-volume"
  }
}

resource "aws_ebs_volume" "nexus_volume" {
  availability_zone = aws_instance.nexus.availability_zone
  size              = 15  # Size in GB
  type              = "gp2"  # General Purpose SSD

  tags = {
    Name = "nexus-volume"
  }
}

# Attach the EBS volumes to the EC2 instances
resource "aws_volume_attachment" "sonarqube_attachment" {
  device_name = "/dev/xvdf"  # The device name may vary; choose one that's available
  volume_id   = aws_ebs_volume.sonarqube_volume.id
  instance_id = aws_instance.sonarqube.id
}

resource "aws_volume_attachment" "nexus_attachment" {
  device_name = "/dev/xvdf"  # The device name may vary; choose one that's available
  volume_id   = aws_ebs_volume.nexus_volume.id
  instance_id = aws_instance.nexus.id
}

# Output the instance IP addresses and volume IDs
output "sonarqube_ip" {
  value = aws_instance.sonarqube.public_ip
}

output "nexus_ip" {
  value = aws_instance.nexus.public_ip
}

output "sonarqube_volume_id" {
  value = aws_ebs_volume.sonarqube_volume.id
}

output "nexus_volume_id" {
  value = aws_ebs_volume.nexus_volume.id
}

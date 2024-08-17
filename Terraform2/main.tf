provider "aws" {
  region = "us-east-1" # Change this to your desired region
}

# Create a new VPC
resource "aws_vpc" "new_vpc" {
  cidr_block = "10.1.0.0/16" # Adjust CIDR block as needed
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
}

# Create public subnets in different availability zones
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.new_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.new_vpc.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-subnet-b"
  }
}

# Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.new_vpc.id
  tags = {
    Name = "eks-igw"
  }
}

# Create a route table and associate it with the public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.new_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "eks-public-rt"
  }
}

resource "aws_route_table_association" "subnet_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a security group for the EKS cluster
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.new_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-sg"
  }
}

# Create IAM Role for EKS Cluster
resource "aws_iam_role" "eks_admin_role" {
  name = "eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_policy" {
  role     = aws_iam_role.eks_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create EKS Cluster
resource "aws_eks_cluster" "example" {
  name     = "example-cluster"
  role_arn  = aws_iam_role.eks_admin_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.subnet_a.id,
      aws_subnet.subnet_b.id
    ]
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

# Create Launch Template for EKS Node Group
resource "aws_launch_template" "eks_launch_template" {
  name_prefix   = "eks-launch-template-"
  image_id       = "ami-04a81a99f5ec58529" # Update with the appropriate AMI for EKS
  instance_type  = "t2.medium"

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [aws_security_group.eks_sg.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "eks-node"
    }
  }
}

# Create EKS Node Group
resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example-node-group"
  node_role_arn   = aws_iam_role.eks_admin_role.arn
  subnet_ids      = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  launch_template {
    id      = aws_launch_template.eks_launch_template.id
    version = "$Latest"
  }

  depends_on = [
    aws_eks_cluster.example
  ]
}

output "cluster_endpoint" {
  value = aws_eks_cluster.example.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.example.certificate_authority[0].data
}

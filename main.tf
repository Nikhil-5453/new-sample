#VPC
resource "aws_vpc" "my_project_vpc" {
  cidr_block = var.vpc_cidr
  tags= {
    Name= "Terraform_VPC"
  }
}

#Public subnet 1
resource "aws_subnet" "pub_S1" {
  vpc_id = aws_vpc.my_project_vpc.id
  cidr_block = var.subnet_cidrs[0]
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
  tags= {
    Name= "Terraform_vpc_pub_sub1"
  }
}

#Public subnet 2
resource "aws_subnet" "pub_S2" {
    vpc_id = aws_vpc.my_project_vpc.id 
    cidr_block = var.subnet_cidrs[1]
    availability_zone = "ap-south-1b" 
    map_public_ip_on_launch = true
    tags= {
    Name= "Terraform_vpc_pub_sub2"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_project_vpc.id
   tags= {
    Name= "Terraform_vpc_IGW"
  }
}

#Route Table
resource "aws_route_table" "my_rtb" {
  vpc_id = aws_vpc.my_project_vpc.id
   route  {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.my_igw.id
   }

   tags= {
    Name= "Terraform_vpc_RTB"
  }
}

#Route Table Subnet-1 Association
resource "aws_route_table_association" "rtbs1" {
  route_table_id = aws_route_table.my_rtb.id
  subnet_id = aws_subnet.pub_S1.id
  
}

#Route Table Subnt-2 Association
resource "aws_route_table_association" "rtbs2" {
  route_table_id = aws_route_table.my_rtb.id
  subnet_id = aws_subnet.pub_S2.id
}

#Security Group
resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "My security group"
  vpc_id      = aws_vpc.my_project_vpc.id

  ingress {
    description = "HTTP Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Traffic allowed out of VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "my_proj_sg"
  }
}


# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_policy" {
  name        = "myporj_s3_policy"
  description = "Policy for EC2 to access S3"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [        // given all kinds of actions to IAM
          "s3:*",                  
          "s3-object-lambda:*"
        ],
        "Resource":"*"
      }
    ]
  })
  tags = {
    Name = "myporj_s3_policy"
  }
}

# Attach IAM S3 Policy to the Role
resource "aws_iam_role_policy_attachment" "s3_policy_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

# IAM Instance Profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_role_profile"
  role = aws_iam_role.ec2_role.name
}

#EC2 Instance 1
resource "aws_instance" "ser1" {
  ami               = var.ami_name
  instance_type     = var.inst_typee
  key_name          = "Pair1"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id = aws_subnet.pub_S1.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  tags = {
    Name = "Server1"
  }
}

#EC2 Instance 2
resource "aws_instance" "ser2" {
  ami               = var.ami_name
  instance_type     = var.inst_typee
  key_name          = "Pair1"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id = aws_subnet.pub_S2.id
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  tags = {
    Name = "Server2"
  }
}

# S3 Bucket
resource "aws_s3_bucket" "Terrform_VPC_Bucket" {
  bucket = "nikhilterraformvpcproj"

  tags = {
    Name = "Terraform_VPC_Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_pub_acc" {
  bucket = aws_s3_bucket.Terrform_VPC_Bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


#Creating Load balancer (ALB)
resource "aws_lb" "My_lb" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.pub_S1.id]
  

  access_logs {
    bucket  = aws_s3_bucket.Terrform_VPC_Bucket.id
    prefix  = "My_lb-lb"
    enabled = true
  }

  tags = {
    Name = "Terraform_VPC_ALB" 
  }
}

#Creating Target Group for ALB
resource "aws_lb_target_group" "lb_tg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_project_vpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
  tags = {
    Name = "My_TG" 
  }
}

#ALB Target grp attachment to Server-1 instance
resource "aws_lb_target_group_attachment" "S1_tg" {
  target_id        = aws_instance.ser1.id
  target_group_arn = aws_lb_target_group.lb_tg.arn
  port             = 80
}

#ALB Target grp attachment to Server-2 instance
resource "aws_lb_target_group_attachment" "S2_tg" {
  target_id        = aws_instance.ser2.id
   target_group_arn = aws_lb_target_group.lb_tg.arn
  port             = 80
}

#ALB Listener attachment
resource "aws_lb_listener" "lb_lis" {
  load_balancer_arn = aws_lb.My_lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.lb_tg.arn
    type = "forward"
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-north-1a"  # Subnet in AZ A

  tags = {
    Name = "public-subnet"
  }
  
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"  # Different CIDR block for the new public subnet
  availability_zone = "eu-north-1b"  # Ensure it's in a different Availability Zone

  tags = {
    Name = "public-subnet-b"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"  # New CIDR block
  availability_zone = "eu-north-1a"  # Subnet in AZ A

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1b"  # Subnet in AZ B

  tags = {
    Name = "private-subnet-b"
  }
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]  # Subnets from different AZs

  tags = {
    Name = "my-db-subnet-group"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow-all"
  }
}

resource "aws_instance" "my_instance" {
  ami           = var.ec2_ami
  instance_type = var.ec2_instance_type
  key_name      = var.key_name
  subnet_id     = aws_subnet.public_subnet.id
  # security_groups = [aws_security_group.allow_all.name]  # Use the security group name here

  

  user_data = file(var.user_data_script)

  tags = {
    Name = "my-instance"
  }
}

resource "aws_db_instance" "my_db_instance" {
  allocated_storage    = 20
  engine               = "mariadb"
  instance_class       = "db.t3.micro"
  username             = var.db_user
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name
  skip_final_snapshot  = true

  tags = {
    Name = "my-db-instance"
  }
}



resource "aws_lb" "my_lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_all.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_b.id]  # I specified the same subnet twice, i will come back and check it out.


  enable_deletion_protection = false

  tags = {
    Name = "my-lb"
  }
}


resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_listener" "my_lb_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

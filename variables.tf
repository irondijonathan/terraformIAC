variable "region" {
  description = "The AWS region to deploy to"
}

variable "key_name" {
  description = "The name of the SSH key pair"
}

variable "db_user" {
  description = "The username for the MariaDB database"
}

variable "db_password" {
  description = "The password for the MariaDB database"
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instance"
}

variable "ec2_instance_type" {
  description = "Instance type for EC2 instance"
}

variable "user_data_script" {
  description = "User data script to bootstrap the instance"
}

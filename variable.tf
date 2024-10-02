variable "vpc_cidr" {
  type = string
  description = "Vpc CIDR range"
}

variable "subnet_cidrs" {
  description = "A list of CIDR blocks for the subnets"
  type        = list(string)
}

variable "ami_name" {
  type = string
  description = "Instance AMI"
}

variable "inst_typee" {
  type = string
  description = "Instance type"
}


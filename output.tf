output "aws_vpc" {
    value = aws_vpc.my_project_vpc.id
}

output "subnet1_id" {
  value = aws_subnet.pub_S1
}

output "subnet2_id" {
  value = aws_subnet.pub_S2
}

output "aws_internet_gateway" {
  value = aws_internet_gateway.my_igw.id
}

output "aws_route_table" {
  value = aws_route_table.my_rtb.id
}

output "ALB_DNS" {
  value = aws_lb.My_lb.dns_name
}
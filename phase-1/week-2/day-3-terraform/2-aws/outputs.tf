output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "security_group_id" {
  description = "ID of the web security group."
  value       = aws_security_group.web.id
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.web.id
}

output "elastic_ip" {
  description = "Elastic IP attached to the EC2 instance."
  value       = aws_eip.web.public_ip
}

output "web_url" {
  description = "HTTP URL for the nginx page."
  value       = "http://${aws_eip.web.public_ip}"
}

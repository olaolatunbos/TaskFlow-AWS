output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "vpc_endpoint_ids" {
  description = "IDs of the interface VPC endpoints, keyed by service name"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 gateway VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.this.id
}

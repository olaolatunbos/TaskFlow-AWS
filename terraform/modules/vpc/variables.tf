variable "name" {
  description = "Name prefix used to tag VPC resources"
  type        = string
  default     = "vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across (exactly 2)"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# The private subnets have no NAT gateway, so anything a task needs to reach
# must have an endpoint here. ecr.api + ecr.dkr (with the S3 gateway endpoint,
# which is always created) are the minimum for Fargate image pulls; add "logs"
# alongside them if the task definition ever gains an awslogs configuration.
variable "interface_endpoint_services" {
  description = "AWS service names to create interface VPC endpoints for, without the com.amazonaws.<region> prefix"
  type        = list(string)
  default     = ["ecr.api", "ecr.dkr"]
}

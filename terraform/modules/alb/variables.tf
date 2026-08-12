variable "name" {
  description = "Name prefix for the ALB and its related resources"
  type        = string
  default     = "ecs-app"
}

variable "vpc_id" {
  description = "ID of the VPC the ALB and target group are created in"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs the internet-facing ALB is placed in (at least two, in different AZs)"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal (private). false = internet-facing"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate to attach to the HTTPS (443) listener"
  type        = string
}

variable "ssl_policy" {
  description = "SSL/TLS security policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB's production listeners (80/443)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "test_listener_port" {
  description = "Port of the CodeDeploy test traffic listener, used to validate the green task set before shifting production traffic"
  type        = number
  default     = 8443
}

variable "test_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the test listener. Keep this private: it serves the unvalidated green task set"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "target_port" {
  description = "Port the target group forwards traffic to on the ECS tasks"
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "HTTP path the target group health check requests"
  type        = string
  default     = "/health"
}

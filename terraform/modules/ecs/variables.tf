variable "name" {
  description = "Name prefix for the CodeDeploy application, deployment group and service role"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "white-hart"
}

variable "container_insights" {
  description = "Whether CloudWatch Container Insights is enabled on the cluster"
  type        = string
  default     = "enabled"
}

variable "container_name" {
  description = "Name of the container in the task definition"
  type        = string
  default     = "app"
}

variable "task_family" {
  description = "Family name of the ECS task definition"
  type        = string
  default     = "service"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "service"
}

variable "image_repository_url" {
  description = "ECR Public repository URI to pull the container image from, e.g. public.ecr.aws/<alias>/<repository>"
  type        = string
}

variable "image_tag" {
  description = "Tag of the image to pull from the ECR Public repository"
  type        = string
  default     = "latest"
}

# --- Blue/green wiring, supplied by the ALB module --------------------------

variable "blue_target_group_arn" {
  description = "ARN of the blue target group the ECS service is initially registered with"
  type        = string
}

variable "blue_target_group_name" {
  description = "Name of the blue target group in the CodeDeploy target group pair"
  type        = string
}

variable "green_target_group_name" {
  description = "Name of the green target group in the CodeDeploy target group pair"
  type        = string
}

variable "prod_listener_arn" {
  description = "ARN of the ALB listener carrying production traffic, which CodeDeploy swaps between target groups"
  type        = string
}

variable "test_listener_arn" {
  description = "ARN of the ALB listener carrying test traffic to the replacement task set"
  type        = string
}

variable "deployment_config_name" {
  description = "CodeDeploy deployment configuration controlling how traffic shifts, e.g. CodeDeployDefault.ECSAllAtOnce or CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
  type        = string
  default     = "CodeDeployDefault.ECSAllAtOnce"
}

variable "termination_wait_time_in_minutes" {
  description = "How long CodeDeploy keeps the old (blue) task set running after a successful cutover, during which a rollback is an instant listener swap"
  type        = number
  default     = 5
}

variable "vpc_id" {
  description = "ID of the VPC the ECS service's security group is created in"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC, used to scope the ECS service security group's ingress rule"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs the ECS service's tasks are placed in"
  type        = list(string)
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 3000
}

variable "task_cpu" {
  description = "Fargate task-level vCPU units"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Fargate task-level memory (MiB)"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of task copies to run in the service"
  type        = number
  default     = 2
}

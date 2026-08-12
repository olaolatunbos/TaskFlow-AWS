output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB (use this to reach the app)"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the ALB, for alias records"
  value       = aws_lb.this.zone_id
}

# The ECS service registers against blue; CodeDeploy owns the swap from there.
output "blue_target_group_arn" {
  description = "ARN of the blue target group, the one the ECS service is initially registered with"
  value       = aws_lb_target_group.blue.arn
}

output "blue_target_group_name" {
  description = "Name of the blue target group, for the CodeDeploy target group pair"
  value       = aws_lb_target_group.blue.name
}

output "green_target_group_arn" {
  description = "ARN of the green target group, which CodeDeploy shifts traffic to during a deployment"
  value       = aws_lb_target_group.green.arn
}

output "green_target_group_name" {
  description = "Name of the green target group, for the CodeDeploy target group pair"
  value       = aws_lb_target_group.green.name
}

output "security_group_id" {
  description = "ID of the ALB's security group"
  value       = aws_security_group.alb.id
}

output "https_listener_arn" {
  description = "ARN of the ALB HTTPS listener, CodeDeploy's production traffic route"
  value       = aws_lb_listener.https.arn
}

output "test_listener_arn" {
  description = "ARN of the ALB test listener, CodeDeploy's test traffic route"
  value       = aws_lb_listener.test.arn
}

output "http_listener_arn" {
  description = "ARN of the ALB HTTP (redirect) listener"
  value       = aws_lb_listener.http.arn
}

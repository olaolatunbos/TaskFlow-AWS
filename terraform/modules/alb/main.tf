# Internet-facing ALB is intentional: it serves the public application.
#trivy:ignore:AWS-0053
resource "aws_lb" "this" {
  name                       = "${var.name}-alb"
  internal                   = var.internal
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_lb_target_group" "blue" {
  name        = "${var.name}-blue-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.name}-blue-tg"
  }
}

resource "aws_lb_target_group" "green" {
  name        = "${var.name}-green-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.name}-green-tg"
  }
}

# HTTP listener only redirects to HTTPS (no plaintext app traffic is served).
#trivy:ignore:AWS-0054
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Production traffic route for CodeDeploy. The blue target group is only the
# initial default action: CodeDeploy swaps this listener between blue and green
# on every deployment, so Terraform must not try to swap it back.
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

# Test traffic route for CodeDeploy: lets the replacement task set be validated
# on 8443 before production traffic is shifted to it.
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.test_listener_port
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "Allow inbound HTTP to the ALB and all outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from allowed CIDRs (redirected to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ingress_cidr_blocks
  }

  # CodeDeploy's test traffic route. Scoped to the VPC by default so the
  # unvalidated green task set is never reachable from the internet.
  ingress {
    description = "Test listener from allowed CIDRs"
    from_port   = var.test_listener_port
    to_port     = var.test_listener_port
    protocol    = "tcp"
    cidr_blocks = var.test_ingress_cidr_blocks
  }


  # Open egress required: the ALB must reach targets and the internet.
  #trivy:ignore:AWS-0104
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name}-alb"
  }
}

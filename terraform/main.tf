module "ecr" {
  source = "./modules/ecr"

  name = local.env.ecr_repository_name
}

module "vpc" {
  source = "./modules/vpc"

  name                 = local.name
  vpc_cidr             = local.env.vpc_cidr
  public_subnet_cidrs  = local.env.public_subnet_cidrs
  private_subnet_cidrs = local.env.private_subnet_cidrs
}

module "certificate" {
  source = "./modules/certificate"

  domain_name      = local.env.hostname
  hosted_zone_name = var.hosted_zone_name
}

module "alb" {
  source = "./modules/alb"

  name              = local.name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn   = module.certificate.certificate_arn
  target_port       = var.container_port
  health_check_path = "/health"

  # CodeDeploy's test listener serves the unvalidated green task set, so it is
  # reachable only from inside this workspace's VPC.
  test_ingress_cidr_blocks = [local.env.vpc_cidr]
}

# Point the workspace's hostname at the ALB.
module "dns" {
  source = "./modules/dns"

  zone_id        = module.certificate.zone_id
  record_name    = local.env.hostname
  alias_dns_name = module.alb.alb_dns_name
  alias_zone_id  = module.alb.alb_zone_id
}

module "ecs" {
  source = "./modules/ecs"

  name         = local.name
  cluster_name = local.name
  task_family  = "${local.name}-task"
  service_name = "${local.name}-service"

  image_repository_url = local.env.image_repository_url
  image_tag            = local.env.image_tag

  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids

  # Blue/green wiring: the service starts on blue, and CodeDeploy shifts the
  # production listener between the two target groups on each deployment.
  blue_target_group_arn   = module.alb.blue_target_group_arn
  blue_target_group_name  = module.alb.blue_target_group_name
  green_target_group_name = module.alb.green_target_group_name
  prod_listener_arn       = module.alb.https_listener_arn
  test_listener_arn       = module.alb.test_listener_arn

  container_port = var.container_port
  desired_count  = local.env.desired_count
  task_cpu       = local.env.task_cpu
  task_memory    = local.env.task_memory

  # Ensure the ALB listener/target group are fully wired before ECS
  # registers the service against the target group.
  depends_on = [module.alb]
}

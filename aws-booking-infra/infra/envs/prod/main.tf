locals {
  name = "booking-${var.environment}"
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "ecs" {
  source = "../../modules/ecs"

  name               = local.name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  container_image = "nginx:alpine"
  task_cpu        = 512
  task_memory     = 1024
  desired_count   = 2
}

module "rds" {
  source = "../../modules/rds"

  name                  = local.name
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  ecs_security_group_id = module.ecs.ecs_security_group_id

  instance_class        = "db.t4g.medium"
  allocated_storage     = 50
  max_allocated_storage = 200

  database_name     = "bookings"
  database_username = "booking_admin"
  database_password = var.db_password

  backup_retention_days = 14
  deletion_protection   = true
  multi_az              = true
  skip_final_snapshot   = false
}

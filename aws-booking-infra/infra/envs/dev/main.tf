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
  task_cpu        = 256
  task_memory     = 512
  desired_count   = 1
}

module "rds" {
  source = "../../modules/rds"

  name                   = local.name
  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
  ecs_security_group_id  = module.ecs.ecs_security_group_id

  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  max_allocated_storage  = 50
  database_name          = "bookings"
  database_username      = "booking_admin"
  database_password      = var.db_password

  backup_retention_days   = 3
  deletion_protection     = false
  multi_az                = false
  skip_final_snapshot     = true
}

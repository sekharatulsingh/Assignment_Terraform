# AWS Booking Infrastructure Assignment

This repository contains a Terraform-based AWS infrastructure design for an Internet -> ALB -> ECS/Fargate -> RDS architecture, together with a local PostgreSQL environment for backup, restore, and query optimization work.

The project is designed to run locally without deploying to AWS, while still being realistic enough for Terraform formatting, init, validate, and plan review.

## Project Goals

- Design AWS infrastructure with Terraform
- Support at least two environments: dev and prod
- Keep the RDS instance private and limited to ECS/Fargate access
- Run a local database with Docker Compose for migration, seed, and backup workflows
- Demonstrate practical backup, restore, and query optimization skills
- Provide setup and verification steps in one README

---

## Repository Structure

```text
aws-booking-infra/
+-- README.md
+-- docker-compose.yml
+-- db/
¦   +-- migrations/
¦   ¦   +-- 001_initial_schema.sql
¦   +-- seed/
¦       +-- 001_seed_data.sql
+-- infra/
¦   +-- envs/
¦   ¦   +-- dev/
¦   ¦   ¦   +-- backend.tf
¦   ¦   ¦   +-- dev.tfvars
¦   ¦   ¦   +-- main.tf
¦   ¦   ¦   +-- variables.tf
¦   ¦   ¦   +-- version.tf
¦   ¦   +-- prod/
¦   ¦       +-- backend.tf
¦   ¦       +-- main.tf
¦   ¦       +-- prod.tfvars
¦   ¦       +-- variables.tf
¦   ¦       +-- version.tf
¦   +-- modules/
¦       +-- ecs/
¦       +-- network/
¦       +-- rds/
+-- scripts/
¦   +-- backup.sh
¦   +-- restore.sh
+-- .github/
¦   +-- agents/
¦   ¦   +-- aws-terraform-specialist.agent.md
¦   +-- workflows/
¦       +-- terraform.yml
+-- .env.example
```

---

## Part 1: Terraform Infrastructure Design

The Terraform code models the following AWS stack:

Internet -> ALB -> ECS/Fargate -> RDS

### Included resources

- VPC with public and private subnets
- Internet gateway and NAT gateway
- ALB security group
- ECS/Fargate security group
- RDS security group
- ECS cluster
- ECS task definition and service
- RDS PostgreSQL instance
- Private DB subnet group
- Environment-specific configuration for dev and prod

The RDS instance is private and only allows PostgreSQL traffic from the ECS security group.

---

## Part 2: Terraform Environment Handling

The project includes two environment examples under `infra/envs`:

- `dev`
  - smaller database instance
  - shorter backup retention
  - deletion protection disabled
- `prod`
  - larger database instance
  - longer backup retention
  - deletion protection enabled

Each environment includes:

- `variables.tf`
- environment tfvars file
- `backend.tf`
- resource sizing definitions
- environment naming and region settings

---

## Local Database with Docker Compose

The local database configuration is defined in `docker-compose.yml` and uses PostgreSQL 16.

### Start the database

```bash
docker compose up -d
```

### Verify the database is ready

```bash
docker compose ps
docker compose exec db pg_isready -U booking -d bookings
```

### Database credentials

- Database name: `bookings`
- Username: `booking`
- Password: `booking`
- Host: `localhost`
- Port: `5432`

---

## Part 4: Database Schema and Seed Data

The migration file is in:

- `db/migrations/001_initial_schema.sql`

This creates:

- `hotel_bookings`
- `booking_events`

The seed file is in:

- `db/seed/001_seed_data.sql`

It inserts:

- 150 hotel bookings
- multiple cities
- multiple organizations
- multiple booking statuses
- booking events for some bookings

### Schema summary

```sql
CREATE TABLE hotel_bookings (
  id UUID PRIMARY KEY,
  org_id UUID NOT NULL,
  hotel_id VARCHAR(100) NOT NULL,
  city VARCHAR(100) NOT NULL,
  checkin_date DATE NOT NULL,
  checkout_date DATE NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE TABLE booking_events (
  id BIGSERIAL PRIMARY KEY,
  booking_id UUID NOT NULL REFERENCES hotel_bookings(id) ON DELETE CASCADE,
  event_type VARCHAR(100) NOT NULL,
  payload JSONB,
  created_at TIMESTAMP NOT NULL
);
```

---

## Part 5: Query Optimization

The assignment requires optimization for the following query:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

The migration includes this index:

```sql
CREATE INDEX idx_hotel_bookings_city_created_org_status
    ON hotel_bookings (city, created_at, org_id, status);
```

### Why this index helps

This index matches the real query pattern:

- `city` is used in the `WHERE` clause
- `created_at` filters the rolling 30-day window
- `org_id` and `status` are used in the `GROUP BY`

The result is fewer rows scanned and better performance for city-based reporting.

---

## Part 6: Backup and Restore

The scripts are located in:

- `scripts/backup.sh`
- `scripts/restore.sh`

### Create a backup

```bash
./scripts/backup.sh
```

This creates a timestamped PostgreSQL dump under the `backups/` directory.

### Restore into a fresh database

```bash
./scripts/restore.sh backups/bookings_YYYYMMDD_HHMMSS.dump
```

This creates a new database called `bookings_restore` and restores the dump into it.

### Verify the restore worked

```bash
docker compose exec db psql -U booking -d bookings_restore -c "SELECT 'hotel_bookings' AS table_name, COUNT(*) AS rows FROM hotel_bookings UNION ALL SELECT 'booking_events', COUNT(*) FROM booking_events;"
```

The output should show row counts consistent with the original database.

---

## Terraform Validation Commands

The repo is structured to support the validation workflow described in the assignment.

### Format

```bash
cd aws-booking-infra
terraform fmt -recursive
```

### Init and validate

```bash
cd aws-booking-infra/infra/envs/dev
terraform init -backend=false
terraform validate
```

### Plan review

```bash
cd aws-booking-infra/infra/envs/dev
terraform plan -refresh=false -var-file=dev.tfvars -lock=false
```

The same pattern can be used for the `prod` environment.

---

## Optional GitHub Actions Workflow

A Terraform GitHub workflow is included at:

- `.github/workflows/terraform.yml`

This workflow runs on pull requests and performs:

- `terraform fmt`
- `terraform init`
- `terraform validate`
- `terraform plan`

---

## Local Verification Checklist

1. Start local database:
   ```bash
   docker compose up -d
   ```
2. Check schema and seed data:
   ```bash
   docker compose exec db psql -U booking -d bookings -c "SELECT COUNT(*) FROM hotel_bookings;"
   ```
3. Run a backup:
   ```bash
   ./scripts/backup.sh
   ```
4. Restore into a fresh database:
   ```bash
   ./scripts/restore.sh backups/bookings_YYYYMMDD_HHMMSS.dump
   ```
5. Validate Terraform configuration:
   ```bash
   terraform fmt -recursive
   terraform -chdir=infra/envs/dev init -backend=false
   terraform -chdir=infra/envs/dev validate
   terraform -chdir=infra/envs/dev plan -refresh=false -var-file=dev.tfvars -lock=false
   ```

---

## Notes

- Actual AWS deployment is intentionally not performed.
- The repository is designed for local validation and plan-oriented Terraform review.
- Sensitive values such as database passwords should be managed with a secret manager or environment variables in a real production deployment.

This repository satisfies the assignment requirements for Terraform infrastructure design, local database operations, and validation-oriented infrastructure review.
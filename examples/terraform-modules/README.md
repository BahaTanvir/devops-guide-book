# Terraform Modules

This directory contains reusable Terraform modules used throughout the book.

## Available Modules

### Infrastructure Modules
- **vpc/** - AWS VPC with public/private subnets
- **eks-cluster/** - EKS cluster with node groups
- **rds/** - RDS database instances
- **s3-bucket/** - S3 bucket with security defaults

### Application Modules
- **web-service/** - Standard web service deployment
- **api-gateway/** - API Gateway configuration
- **lambda-function/** - Lambda function with common settings

### Monitoring Modules
- **prometheus/** - Prometheus monitoring stack
- **cloudwatch-alarms/** - CloudWatch alarms for common scenarios

## Module Structure

Each module follows this structure:
```
module-name/
├── README.md           # Module documentation
├── main.tf            # Main resources
├── variables.tf       # Input variables
├── outputs.tf         # Output values
├── versions.tf        # Provider versions
└── examples/          # Usage examples
    └── basic/
        ├── main.tf
        └── README.md
```

## Usage

```hcl
module "vpc" {
  source = "./terraform-modules/vpc"
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
  
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

## Best Practices

- All modules include input validation
- Sensible defaults for common use cases
- Tagged with environment and project
- Security best practices applied
- Cost-optimized where possible

*Modules coming soon...*

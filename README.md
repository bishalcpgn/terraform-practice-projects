# terraform-practice

Hands-on AWS infrastructure built with Terraform. Each folder is a
self-contained project with its own state and README.

| # | Project | Key concepts |
|---|---------|--------------|
| [01](./01-static-website-s3-cloudfront) | Static website on S3 + CloudFront | Modules, OAC, `moved` blocks, IAM policy documents |

## Running any project

```bash
cd 01-static-website-s3-cloudfront
terraform init
terraform plan
```

State is local. These are practice projects, not production stacks.

# Static Website Hosting using Terraform

Private static website hosting on AWS. An S3 bucket with no public access,
fronted by CloudFront using Origin Access Control (OAC) over HTTPS.

## Architecture

```
   Browser
      │  https://xxxxxxxx.cloudfront.net
      ▼
 ┌──────────────────────┐
 │  CloudFront          │
 │  • redirect-to-https │
 │  • OAC (SigV4)       │
 └──────────┬───────────┘
            │ signed request over the AWS backbone
            ▼
 ┌──────────────────────────────────┐
 │  S3 bucket (PRIVATE)             │
 │  • Block Public Access: all on   │
 │  • ACLs disabled                 │
 │  • SSE-S3, versioned             │
 │  • Policy: only THIS distribution│
 └──────────────────────────────────┘
```

The bucket has no website endpoint and no public read. CloudFront authenticates
to S3 with SigV4, and the bucket policy grants access only to the CloudFront
service principal with an `AWS:SourceArn` condition pinning it to this one
distribution.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13 |
| aws provider | ~> 6.63 |

State is local. This is a practice repository.

## Usage

```bash
terraform init
terraform plan
terraform apply

BUCKET=$(terraform output -raw bucket_name)
aws s3 cp site/index.html "s3://$BUCKET/index.html" \
  --content-type "text/html; charset=utf-8"

terraform output -raw website_url
```

Terraform owns the bucket. The upload step owns the objects. Content is
deliberately not managed by Terraform.

## Layout

| Path | Purpose |
|------|---------|
| `main.tf` | Module call |
| `modules/static-site/` | The reusable stack |
| `site/` | Web content, uploaded via the AWS CLI |
| `docs/` | Notes on concepts used |

## Module inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name_prefix` | string | — | Prefix for all resource names |
| `default_root_object` | string | `index.html` | Object served for `/` |
| `price_class` | string | `PriceClass_100` | CloudFront edge coverage |
| `force_destroy` | bool | `false` | Allow destroying a non-empty bucket |
| `noncurrent_version_expiration_days` | number | `7` | Old version retention |

Deliberately **not** configurable: HTTPS redirect, Block Public Access, OAC
signing. Those are the module's guarantees, not its options.

## Verifying the security model

```bash
URL=$(terraform output -raw website_url)
BUCKET=$(terraform output -raw bucket_name)
REGION=$(aws s3api get-bucket-location --bucket "$BUCKET" --output text)

curl -sI "$URL" | head -1                                       # 200
curl -sI "http://${URL#https://}" | head -1                      # 301
curl -sI "https://$BUCKET.s3.$REGION.amazonaws.com/index.html" | head -1   # 403
```

The 403 is the point. Content is reachable only through CloudFront.

## Known limitations

- Uses CloudFront's default certificate, so `minimum_protocol_version` cannot
  be set. Enforcing TLS 1.2+ requires a custom domain and an ACM certificate.
- CloudFront pricing plans are not manageable via Terraform
  ([provider issue #45450](https://github.com/hashicorp/terraform-provider-aws/issues/45450)).
  This distribution uses pay-as-you-go.
- `force_destroy = true` is set in `main.tf` for sandbox use.
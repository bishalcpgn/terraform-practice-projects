# `moved` blocks: state refactoring without destroying infrastructure

## Why this document exists

This configuration started as a flat set of resources in the root module. It was
later refactored: every resource was moved into `./modules/static-site` so the
stack could be reused and called more than once.

The `moved` blocks below performed that relocation in state. They have since been
removed from the configuration, because they had already done their job.

## What `moved` blocks do

Terraform state maps a resource **address** to a real AWS object:

```
aws_s3_bucket.site  ->  my-bucket-123456789012
```

Refactoring changes the address. Terraform cannot tell "renamed" apart from
"old one deleted, new one created", because the config diff looks identical.
So it plans the destructive interpretation.

A `moved` block tells Terraform: **same object, new address.** It rewrites the
state entry and makes zero AWS API calls. Nothing is destroyed, and the site
stays up throughout.

## The result of this refactor

Moving 9 root-level resources into the module:

| | Plan |
|---|---|
| Without `moved` blocks | `9 to add, 0 to change, 9 to destroy` |
| With `moved` blocks | `0 to add, 0 to change, 0 to destroy` |

## Address pattern

```
module.<call_name>.<original_address>
```

## Notes

- Data sources need no `moved` blocks. They hold no infrastructure.
- Keep `moved` blocks for one release cycle so anyone applying from older state
  gets the same relocation. Then delete them.
- Prefer `moved` over `terraform state mv`. It is declarative, reviewable in a
  PR, and runs identically for everyone.

## Related blocks

| Block | Purpose |
|---|---|
| `import { to = <addr>  id = "<aws-id>" }` | Adopt existing infrastructure into state |
| `removed { from = <addr>  lifecycle { destroy = false } }` | Drop from state, keep the resource |

## The blocks that were used

```hcl
moved {
  from = aws_s3_bucket.site
  to   = module.site.aws_s3_bucket.site
}

moved {
  from = aws_s3_bucket_public_access_block.site
  to   = module.site.aws_s3_bucket_public_access_block.site
}

moved {
  from = aws_s3_bucket_ownership_controls.site
  to   = module.site.aws_s3_bucket_ownership_controls.site
}

moved {
  from = aws_s3_bucket_versioning.site
  to   = module.site.aws_s3_bucket_versioning.site
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.site
  to   = module.site.aws_s3_bucket_server_side_encryption_configuration.site
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.site
  to   = module.site.aws_s3_bucket_lifecycle_configuration.site
}

moved {
  from = aws_s3_bucket_policy.site
  to   = module.site.aws_s3_bucket_policy.site
}

moved {
  from = aws_cloudfront_origin_access_control.site
  to   = module.site.aws_cloudfront_origin_access_control.site
}

moved {
  from = aws_cloudfront_distribution.site
  to   = module.site.aws_cloudfront_distribution.site
}
```
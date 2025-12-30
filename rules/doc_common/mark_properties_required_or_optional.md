Mark every property in the `Arguments Reference` section as `Required` or `Optional` to clearly indicate mandatory and optional fields.

## good

```markdown
## Arguments Reference
...
* `name` - (Required) The name of the resource.
* `resource_group_name` - (Required) The name of the Resource Group where the Cross Region Disaster Recovery Autonomous Database should exist.
* `location` - (Required) The Azure Region where the resource should exist.
* `tags` - (Optional) A mapping of tags to assign to the resource.
...
## Attributes Reference
...
* `id` - The ID of the AAD B2C Directory.
...
```

## bad

```markdown
## Arguments Reference
...
* `name` - The name of the resource.
* `resource_group_name` - The name of the Resource Group where the Cross Region Disaster Recovery Autonomous Database should exist.
* `location` - The Azure Region where the resource should exist.
* `tags` - A mapping of tags to assign to the resource.
...
## Attributes Reference
...
* `id` - The ID of the AAD B2C Directory.
...
```

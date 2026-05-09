The CRUD description in the `## Timeouts` section should follow the format `Used when <doing> the <brand name>`. Do not include extra words like "this" before the brand name.

## good

```markdown
* `create` - (Defaults to 30 minutes) Used when creating the Arc Machine.
* `read` - (Defaults to 5 minutes) Used when retrieving the Arc Machine.
* `update` - (Defaults to 30 minutes) Used when updating the Arc Machine.
* `delete` - (Defaults to 30 minutes) Used when deleting the Arc Machine.
```

## bad

```markdown
* `create` - (Defaults to 30 minutes) Used when creating this Arc Machine.
* `read` - (Defaults to 5 minutes) Used when retrieving this Arc Machine.
* `update` - (Defaults to 30 minutes) Used when updating this Arc Machine.
* `delete` - (Defaults to 30 minutes) Used when deleting this Arc Machine.
```

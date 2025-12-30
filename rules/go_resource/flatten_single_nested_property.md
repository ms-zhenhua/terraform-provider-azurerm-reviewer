Flatten top-level properties with `MaxItems: 1` that contain a single nested property. The `MaxItems: 1` constraint ensures a single element, allowing nested fields to be flattened to simplify the schema. Properties without `MaxItems: 1` are treated as collections and cannot be flattened. This rule applies only to top-level properties.

### good:
```go
func (DatabaseSystemResource) Arguments() map[string]*pluginsdk.Schema {
	return map[string]*pluginsdk.Schema{
        ...
		"certificate": {
            Type:     pluginsdk.TypeList,
            Optional: true,
            Elem:     &pluginsdk.Schema{
                Type:         pluginsdk.TypeString,
                ValidateFunc: validation.StringIsNotEmpty,
            },
        },
        ...
    }
}
```

### good: Properties without `MaxItems: 1` cannot be flattened
```go
func (DatabaseSystemResource) Arguments() map[string]*pluginsdk.Schema {
	return map[string]*pluginsdk.Schema{
        ...
		"credentials": {
            Type:     pluginsdk.TypeList,
            Optional: true,
            Elem:     &pluginsdk.Resource{
                Schema: map[string]*pluginsdk.Schema{
                    "certificate": {
                        Type:     pluginsdk.TypeList,
                        Optional: true,
                        Elem:     &pluginsdk.Schema{
                            Type:         pluginsdk.TypeString,
                            ValidateFunc: validation.StringIsNotEmpty,
                        },
                    },
                },
            },
        },
        ...
    }
}
```

### bad:
```go
func (DatabaseSystemResource) Arguments() map[string]*pluginsdk.Schema {
	return map[string]*pluginsdk.Schema{
        ...
		"credentials": {
            Type:     pluginsdk.TypeList,
            Optional: true,
            MaxItems: 1,
            Elem:     &pluginsdk.Resource{
                Schema: map[string]*pluginsdk.Schema{
                    "certificate": {
                        Type:     pluginsdk.TypeList,
                        Optional: true,
                        Elem:     &pluginsdk.Schema{
                            Type:         pluginsdk.TypeString,
                            ValidateFunc: validation.StringIsNotEmpty,
                        },
                    },
                },
            },
        },
        ...
    }
}
```

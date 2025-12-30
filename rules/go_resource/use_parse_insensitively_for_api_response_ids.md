Use `Parse...Insensitively` methods when parsing IDs from API responses to handle case variations in Azure resource IDs. Use general `Parse...` methods when parsing IDs from `metadata`.

### good: use the general `Parse` method when parsing IDs from `metadata`.
```go
func(ctx context.Context, metadata sdk.ResourceMetaData) error {
    ...
    id, err := commonids.ParseSubnetID(metadata.ResourceData.Id())
    if err != nil {
        return err
    }
    ...
}
```

### good: use `Parse...Insensitively` methods when parsing IDs from API responses
```go
func(ctx context.Context, metadata sdk.ResourceMetaData) error {
    resp, err := client.Get(ctx, *id)
    if err != nil {
        return err
    }
    
    if model := resp.Model; model != nil {
        if prop := model.Properties; prop != nil {
            if prop.Subnet != nil {
                parsedSubnetId, err := commonids.ParseSubnetIDInsensitively(prop.Subnet.Id)
                if err != nil {
                    return err
                }
            }
        }
    }
    return nil
}
```

### bad:
```go
func(ctx context.Context, metadata sdk.ResourceMetaData) error {
    resp, err := client.Get(ctx, *id)
    if err != nil {
        return err
    }
    
    if model := resp.Model; model != nil {
        if prop := model.Properties; prop != nil {
            if prop.Subnet != nil {
                parsedSubnetId, err := commonids.ParseSubnetID(prop.Subnet.Id)
                if err != nil {
                    return err
                }
            }
        }
    }
    return nil
}
```

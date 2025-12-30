When assigning a primitive value to a field that requires a pointer to an enum, use `pointer.ToEnum`. This helper function handles the conversion and pointer creation in a single, type-safe step, avoiding verbose casting or temporary variables.

### good: use pointer.ToEnum for concise conversion
```go
return &managedclusters.ManagedClusterBootstrapProfile{
    SourcePointer: pointer.ToEnum[managedclusters.ArtifactSource](config["source_pointer"].(string)),
}
```

### good: standard casting for non-pointer fields
```go
return &managedclusters.ManagedClusterBootstrapProfile{
    SourceValue: managedclusters.ArtifactSource(config["artifact_source"].(string)),
}
```

### bad: redundant casting before pointer creation
```go
return &managedclusters.ManagedClusterBootstrapProfile{
    ArtifactSource: pointer.To(managedclusters.ArtifactSource(config["artifact_source"].(string))),
}
```

### bad: unnecessary temporary variable and address taking
```go
var source = managedclusters.ArtifactSource(config["artifact_source"].(string))
return &managedclusters.ManagedClusterBootstrapProfile{
    ArtifactSource: &source,
}
```


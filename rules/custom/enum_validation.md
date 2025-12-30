Fields defined as enum types within the `Arguments()` schema must include a `ValidateFunc` using `validation.StringInSlice`.

Typically, `validation.StringInSlice` should utilize the `PossibleValuesFor...` function. However, there are two exceptions:
1. The enum values are defined as constant strings rather than a specific SDK enum type.
2. Internal values (e.g., `None`, `Off`, `Default`) must be excluded from the user-facing schema.

In the documentation's `## Arguments Reference` section, enum fields must list allowed values. Use "Possible values are..." for multiple options, or "The only possible value is..." for a single option. Meanwhile, do not expose any internal values(e.g., `None`, `Off`, `Default`).

Refer to the following examples for correct and incorrect usage:


### Good: Standard usage of PossibleValuesFor
```go
"example_field": {
    Type:         pluginsdk.TypeString,
    Required:     true,
    ValidateFunc: validation.StringInSlice(example.PossibleValuesForExampleFieldEnum(), false),
},
```

### Good: Using constant strings (no SDK enum type)
```go
"example_field": {
    Type:     pluginsdk.TypeString,
    Optional: true,
    ValidateFunc: validation.StringInSlice([]string{
        "example_value1",
        "example_value2",
        // ...
    }, false),
},
```

### Good: Excluding internal values (e.g., None)
```go
"example_field": {
    Type:     pluginsdk.TypeString,
    Optional: true,
    // Note: None value of example.ExampleFieldNone not exposed to the user
    ValidateFunc: validation.StringInSlice([]string{
        string(example.ExampleFieldValue1),
        string(example.ExampleFieldValue2),
        // ...
    }, false),
},
```

### Good: Documentation for multiple enum values
```markdown

`example_field` - (Optional) This argument does something. Possible values are `value1`, `value2`, and `value3`.
```

### Good: Documentation for a single enum value
```markdown

`example_field` - (Optional) This argument does something. The only possible value is `value1`.
```

### Bad: Missing usage of PossibleValuesFor
```go
"example_field": {
    Type:     pluginsdk.TypeString,
    Optional: true,
    ValidateFunc: validation.StringInSlice([]string{
        string(example.ExampleFieldValue1),
        string(example.ExampleFieldValue2),
        // ...
    }, false),
},
```

### Bad: Exposing internal values (e.g., None) in documentation
```markdown

`example_field` - (Optional) This argument does something. Possible values are `value1`, `value2`, and `None`.
```
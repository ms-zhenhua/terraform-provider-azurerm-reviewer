Avoid redundant `Key().Exists()` checks in acceptance tests for fields marked as `Required` or `Optional`. These checks are unnecessary as the SDK handles required fields, and optional fields are defined in the configuration.

``` go
// xxx_resource.go/xxx_data_source.go
func (...) Arguments() map[string]*pluginsdk.Schema {
	return map[string]*pluginsdk.Schema{
		...
		"required_field": {
			Type:         pluginsdk.TypeString,
			Required:     true,
			...
		},
		"optional_field": {
			Type:         pluginsdk.TypeString,
			Optional: 	  true,
			...
		},
		"computed_field": {
			Type:         pluginsdk.TypeString,
			Computed:     true,
			...
		},
		...
	}
}
```

### good:
```go
// xxx_test.go
func TestAccExample_complete(t *testing.T) {
	data := acceptance.BuildTestData(t, "azurerm_example", "test")
	r := ExampleTestResource{}

	data.ResourceTest(t, r, []acceptance.TestStep{
		{
			Config: r.complete(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
				check.That(data.ResourceName).Key("computed_field").Exists(),
			),
		},
		...
	})
}
```

### bad:
```go
// xxx_test.go
func TestAccExample_complete(t *testing.T) {
	data := acceptance.BuildTestData(t, "azurerm_example", "test")
	r := ExampleTestResource{}

	data.ResourceTest(t, r, []acceptance.TestStep{
		{
			Config: r.complete(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
				check.That(data.ResourceName).Key("required_field").Exists(),
				check.That(data.ResourceName).Key("optional_field").Exists(),
				check.That(data.ResourceName).Key("computed_field").Exists(),
			),
		},
		...
	})
}
```

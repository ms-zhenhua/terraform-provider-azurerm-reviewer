Format validation for fields should be put in `ValidateFunc` rather than performed manually in expand/flatten functions.

### good:
```go
"customer_contacts": {
	Type:     pluginsdk.TypeList,
	Optional: true,
	ForceNew: true,
	Elem: &pluginsdk.Schema{
		Type:         pluginsdk.TypeString,
		ValidateFunc: validate.CustomerContactEmail, // validate email format in this function
	},
},
```

### bad:
```go
func expandCloneCustomerContacts(input []string) []autonomousdatabases.CustomerContact {
	...
	if strings.TrimSpace(email) != "" {
		...
	}
	...
}
```

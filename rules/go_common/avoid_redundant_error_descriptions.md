Since the string formatting of an ID already provides the relevant information about the resource type or context, avoid adding redundant descriptive text in error messages.

### good:
```go
return fmt.Errorf("no inventory items were found for %s", scvmmServerId)
```

### bad:
```go
return fmt.Errorf("no inventory items were found for the System Center Virtual Machine Manager Server %q", scvmmServerId)
```

Avoid using the `WaitForStateContext` function. Use a custom poller instead, following the example in https://github.com/hashicorp/terraform-provider-azurerm/blob/main/internal/services/appservice/custompollers/app_service_active_slot_poller.go.

### Bad: using WaitForStateContext for polling
```go
stateConf := &pluginsdk.StateChangeConf{
	Pending:    []string{"Pending"},
	Target:     []string{"Succeeded"},
	Refresh:    resourceRefreshFunc(ctx, client, id),
	Timeout:    d.Timeout(pluginsdk.TimeoutCreate),
	MinTimeout: 10 * time.Second,
}

if _, err := stateConf.WaitForStateContext(ctx); err != nil {
	return fmt.Errorf("waiting for %s to finish: %+v", id, err)
}
```

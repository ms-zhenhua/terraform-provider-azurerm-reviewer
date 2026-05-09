Use the smallest SKU possible in test configurations to minimize resource costs and improve test efficiency.

### good:
```hcl
resource "azurerm_managed_redis_cluster" "test" {
	sku_name = "Balanced_B1"
}
```

### bad:
```hcl
resource "azurerm_managed_redis_cluster" "test" {
	sku_name = "Balanced_B3"
}
```

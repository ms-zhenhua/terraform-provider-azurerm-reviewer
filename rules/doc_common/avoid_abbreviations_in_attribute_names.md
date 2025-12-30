Avoid using abbreviations in field names except for some valid abbreviations below. Use full, descriptive words to ensure clarity and consistency across the provider.

Valid abbreviations:
* `gigabyte` (e.g. `size_in_gb`)
* `Uniform Resource Locator` (e.g. `url`)
* `Uniform Resource Identifier` (e.g. `uri`)
* `Oracle Cloud Identifier` (e.g. `ocid`)
* `Oracle Cloud Infrastructure` (e.g. `oci`)
* `Domain Name System` (e.g. `dns`)
* `Internet Protocol` (e.g. `source_ip`)
* `identifier` (e.g. `id`)
* `administrator`(e.g. `admin_password`)

### good: valid abbreviations
```markdown
* `admin_password` - (Optional) ...
* `dns` - (Optional) ...
* `id` - (Optional) ...
* `oci` - (Optional) ...
* `ocid` - (Optional) ...
* `size_in_gb` - (Optional) ...
* `source_ip` - (Optional) ...
* `uri` - (Optional) ...
* `url` - (Optional) ...
```

### good:
```markdown
* `resource_group_name` - (Required) Specifies the resource group where the resource exists.
* `virtual_machine_id` - (Optional) Specifies the ID of the virtual machine.
* `storage_account_name` - (Required) Specifies the name of the storage account.
* `network_interface_id` - (Optional) Specifies the ID of the network interface.
```

### bad:
```markdown
* `rg_name` - (Required) Specifies the resource group where the resource exists.
* `vm_id` - (Optional) Specifies the ID of the virtual machine.
* `sa_name` - (Required) Specifies the name of the storage account.
* `nic_id` - (Optional) Specifies the ID of the network interface.
```

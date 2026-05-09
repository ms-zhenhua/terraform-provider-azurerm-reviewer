The `## Example Usage` section should only include Required properties. Do not include Optional properties in the example, as they add unnecessary noise and may confuse users about which properties are actually needed.

## bad

```markdown
## Example Usage

...
resource "azurerm_cdn_frontdoor_firewall_policy" "example" {
  ...
  captcha_cookie_expiration_in_minutes      = 45
  ...
}
...
```

where `captcha_cookie_expiration_in_minutes` is documented as Optional in the Argument Reference:

```markdown
## Argument Reference

The following arguments are supported:

...
* `captcha_cookie_expiration_in_minutes` - (Optional) Specifies the Captcha cookie lifetime in minutes. Possible values are between `5` and `1440`. Defaults to `30` minutes.
...
```

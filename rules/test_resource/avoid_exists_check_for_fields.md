Avoid validating `Exists()` for fields as it will be validated by `data.ImportStep`.

### good:
```go
func TestAccBotChannelDirectline_basic(t *testing.T) {
	data := acceptance.BuildTestData(t, "azurerm_bot_channel_directline", "test")
	r := BotChannelDirectlineResource{}

	data.ResourceTest(t, r, []acceptance.TestStep{
		{
			Config: r.basicConfig(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
			),
		},
		data.ImportStep(),
	})
}
```

### bad:
```go
func TestAccBotChannelDirectline_basic(t *testing.T) {
	data := acceptance.BuildTestData(t, "azurerm_bot_channel_directline", "test")
	r := BotChannelDirectlineResource{}

	data.ResourceTest(t, r, []acceptance.TestStep{
		{
			Config: r.basicConfig(data),
			Check: acceptance.ComposeTestCheckFunc(
				check.That(data.ResourceName).ExistsInAzure(r),
				check.That(data.ResourceName).Key("extension_key1").Exists(),
				check.That(data.ResourceName).Key("extension_key2").HasValue("key2"),
			),
		},
		data.ImportStep(),
	})
}
```

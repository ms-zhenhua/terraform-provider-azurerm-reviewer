Avoid creating variables that are used only once. Assign the value directly instead.

### good:
```go
func resourceCdnFrontDoorProfileCreate(d *pluginsdk.ResourceData, meta interface{}) error {
	...
	props.Properties.LogScrubbing = expandCdnFrontDoorProfileLogScrubbing(d.Get("log_scrubbing_rule").(*pluginsdk.Set).List())
	...
}
```

### bad:
```go
func resourceCdnFrontDoorProfileCreate(d *pluginsdk.ResourceData, meta interface{}) error {
	...
	logScrubbing := expandCdnFrontDoorProfileLogScrubbing(d.Get("scrubbing_rule").(*pluginsdk.Set).List())
	props.Properties.LogScrubbing = logScrubbing
	...
}
```

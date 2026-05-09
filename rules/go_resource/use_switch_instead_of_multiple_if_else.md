Use `switch` instead of multiple `if else` for maintainability.

### good:
```go
func expandPersistence(aofBackupFreq string, rdbBackupFreq string) *databases.Persistence {
	...
	switch {
	case aofBackupFreq != "":
		return &databases.Persistence{
			AofEnabled:   pointer.To(true),
			AofFrequency: pointer.ToEnum[databases.AofFrequency](aofBackupFreq),
		}
	case rdbBackupFreq != "":
		return &databases.Persistence{
			RdbEnabled:   pointer.To(true),
			RdbFrequency: pointer.ToEnum[databases.RdbFrequency](rdbBackupFreq),
		}
	default:
		return &databases.Persistence{}
	}
	...
}
```

### bad:
```go
func expandPersistence(aofBackupFreq string, rdbBackupFreq string) *databases.Persistence {
	...
	if rdbBackupFreq == "" && aofBackupFreq == "" {
		return &databases.Persistence{}
	}
	if aofBackupFreq != "" {
		return &databases.Persistence{
			AofEnabled:   pointer.To(true),
			AofFrequency: pointer.ToEnum[databases.AofFrequency](aofBackupFreq),
		}
	} else {
		return &databases.Persistence{
			RdbEnabled:   pointer.To(true),
			RdbFrequency: pointer.ToEnum[databases.RdbFrequency](rdbBackupFreq),
		}
	}
	...
}
```

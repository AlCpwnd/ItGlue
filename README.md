# ItGlue

## ComputerConfig.ps1

> :warning: This script and steps below have yet to be tested.
> Use at your own risk.

The script verify if a report for the current device already exists and will abort if one already exists.

## Requirement

This script will write the report to a shared hosted on a server.
The user will need to have access to the share.

## Setup

The networkpath can be documented within the script under the `$ReportLocation` variable:

```ps
# ======================================================================================================
# Location the report needs to be saved. If none are given, the report will be saved at the script root.
    $ReportLocation = "" 
# ======================================================================================================
```

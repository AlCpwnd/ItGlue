[cmdletbinding()]

# = Mandatory =====================================================================================
    # Location the generated reports.
    $ReportsLocation = "" 
    # Organization you want to document the entries in.
    $Organization = ""
    # Location under to which the configurations need to be associated.
    $Location = ""
# =================================================================================================
# = Optional ======================================================================================
    # Consolidated report location.
    $ConsolidatedReportLocation = ""
    # Enable if you want the reports to be seperated by date.
    $SplitReports = $false
# =================================================================================================

if(!$ReportsLocation -or !$Organization -or !$Location){
    throw "Incomplete parameters."
}

$Reports = Get-ChildItem -Path $ReportsLocation -Filter "*.csv"

$i = 0
$iMax = $Repots.Count
Write-Verbose "$iMax report(s) found."
$ConsolidatedReport = foreach($Report in $Reports){
    Write-Progress -Activity "Consolidating reports for the organization: $Organization" -Status $Report.name -PercentComplete (($i/$iMax)*100)
    $Temp = Import-Csv -Path $Report.FullName -Delimiter ","
    $Temp.organization = $Organization
    $Temp.location
    $Temp
    $i++
}

if(!$ConsolidatedReportLocation){
    $ConsolidatedReportLocation = $PSScriptRoot
}

$FilePath = "$ConsolidatedReportLocation\$Organisation`_$Location.csv"
$FilePath.Replace("\\","\")

if($SplitReports){
    $Date = Get-Date -Format yyyy-MM-dd_HH_mm
    $FilePath.Replace(".csv","`_$Date.csv")
    $ConsolidatedReport | Export-Csv -Path $FilePath -NoClobber -NoTypeInformation -Encoding UTF8 -Delimiter ","
}else{
    $ConsolidatedReport | Export-Csv -Path $FilePath -NoClobber -NoTypeInformation -Encoding UTF8 -Delimiter "," -Append
}

Write-Verbose "Report generated at: $FilePath"
#Requires -RunAsAdministrator

param(
    [Switch]$Test
)

# =================================================================================================
# Location the report needs to be saved. 
    $ReportLocation = "" 
# =================================================================================================

if($Test){
    $ReportLocation = $PSScriptRoot
}

# Stops the script the network destination isn't reachable.
if(!(Test-Path -Path $ReportLocation)){
    throw "No report path given."
}

# Stops if a report already exists for the current computer
if(Get-ChildItem -Path $ReportLocation -Filter "$env:COMPUTERNAME*.csv"){
    return
}

# Manufacturerinfo
$MFInfo = Get-WmiObject -Class Win32_ComputerSystem

# OsInfo
$OsInfo = Get-CimInstance -ClassName CIM_OperatingSystem -Property *

# BiosInfo
$BiosInfo = Get-WmiObject -Class Win32_BIOS

# NICInfo
class NIC {
    [String]$name
    [String]$ip_address
    [String]$notes
    [string]$primary
    [String]$mac_address
    [Int]$port
}

$MainNic = Get-NetIPConfiguration | Where-Object{$_.IPv4DefaultGateway} | Select-Object -First 1
$AdapterConfig = Get-NetAdapter
$NicInfo = foreach($Nic in $AdapterConfig){
    $Test = Get-NetIPAddress -InterfaceAlias $Nic.Name -ErrorAction SilentlyContinue
    $Temp = [NIC]::new()
    $Temp.name = $Nic.Name
    $Temp.ip_address = if($Test){
        (Get-NetIPConfiguration -InterfaceAlias $Nic.Name).IPv4Address.IPAddress
    }else{
        ""
    }
    $Temp.notes = if($Test){
        $Nic.LinkSpeed
    }else{
        "[disconnected]"
    }
    $Temp.primary = if($Nic.Name -eq $MainNic.InterfaceAlias){
        "true"
    }else{
        "false"
    }
    $Temp.mac_address = $Nic.MacAddress.Replace('-',':')
    $Temp.port = $Nic.InterfaceIndex
    $Temp
}

# Report generation

class ItGlueConfig{
    [string]$organization
    [string]$name
    [String]$configuration_type
    [String]$configuration_status
    [String]$hostname
    [String]$pirmary_ip
    [String]$default_gateway
    [String]$mac_address
    [String]$serial_number
    [String]$asset_tag
    [String]$manufacturer
    [String]$model
    [String]$operating_system
    [String]$operating_system_notes
    [String]$position
    [String]$notes
    [String]$installed_at
    [String]$installed_by
    [String]$warranty_expires_at
    [String]$contact
    [String]$location
    [String]$configuration_interfaces
}

$ConfigInfo = [ItGlueConfig]::new()
$ConfigInfo.name = $env:COMPUTERNAME
$ConfigInfo.configuration_type = if($MFInfo.PCSytemType -eq 2){
    'Laptop'
}elseif($OsInfo.Caption -match 'Server'){
    'Server'
}else{
    'WorkStation'
}
if($MFInfo.Manufacturer -match 'VMware'){
    $ConfigInfo.configuration_type = "Virtual $($ConfigInfo.configuration_type)"
}
$ConfigInfo.configuration_status = 'Active'
$ConfigInfo.hostname = $env:COMPUTERNAME
$ConfigInfo.pirmary_ip = $NicInfo[0].ip_address
$ConfigInfo.default_gateway = $MainNic.IPv4DefaultGateway.NextHop
$ConfigInfo.mac_address = ($NicInfo | Where-Object{$_.primary}).mac_address
$ConfigInfo.serial_number = $BiosInfo.SerialNumber
$ConfigInfo.manufacturer = $MFInfo.Manufacturer
$ConfigInfo.model = $MFInfo.Model
$ConfigInfo.operating_system = $OsInfo.Caption
$ConfigInfo.installed_at = $OsInfo.InstallDate.ToString('yyyy-MM-dd')
$ConfigInfo.configuration_interfaces = $NicInfo | ConvertTo-Json -Compress

# Report export
$Date = Get-Date -Format yyyy-MM-dd
$Path = "$ReportLocation\$env:COMPUTERNAME`_$Date.csv" -replace '\\','\'
$ConfigInfo | Export-Csv -Path $Path -NoTypeInformation -NoClobber -Encoding UTF8 -Delimiter ','
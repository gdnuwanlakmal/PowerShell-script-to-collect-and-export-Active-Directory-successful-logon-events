# Set how many days back to look
$DaysBack = 7
$StartDate = (Get-Date).AddDays(-$DaysBack)

# Set export path for CSV file
$ExportPath = "C:\ActiveDirectory_Users_Last7Days.csv"

Write-Host "Collecting logon events since $StartDate..." -ForegroundColor Cyan

# Fetch all 4624 (successful logon) events since $StartDate
$LogonEvents = Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4624
    StartTime = $StartDate
} -ErrorAction SilentlyContinue

# Process and filter results
$ProcessedLogons = $LogonEvents | ForEach-Object {
    $xml = [xml]$_.ToXml()

    $User = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "TargetUserName" } | Select-Object -ExpandProperty '#text'
    $Domain = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "TargetDomainName" } | Select-Object -ExpandProperty '#text'
    $IPAddress = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "IpAddress" } | Select-Object -ExpandProperty '#text'
    $LogonType = $xml.Event.EventData.Data | Where-Object { $_.Name -eq "LogonType" } | Select-Object -ExpandProperty '#text'
    $Time = $_.TimeCreated

    # Exclude system/computer accounts (ending in $), and null usernames
    if ($User -and -not ($User.EndsWith('$'))) {
        [PSCustomObject]@{
            Username   = "$Domain\$User"
            LogonTime  = $Time
            IPAddress  = $IPAddress
            LogonType  = $LogonType
        }
    }
}

# Sort and remove duplicates
$DistinctLogons = $ProcessedLogons | Sort-Object Username, LogonTime -Unique

# Export to CSV
$DistinctLogons | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8

Write-Host "Export complete! File saved to $ExportPath" -ForegroundColor Green

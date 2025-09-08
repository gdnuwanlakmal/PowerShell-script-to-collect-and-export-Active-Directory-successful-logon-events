# PowerShell script to collect and export Active Directory successful logon events
## PowerShell script to collect and export Active Directory successful logon events (Event ID 4624) from the last 7 days into a CSV file for auditing and security monitoring.

### 1. Define the time range
```shell
$DaysBack = 7
$StartDate = (Get-Date).AddDays(-$DaysBack)
```

* Looks back 7 days from the current date.
* $StartDate becomes the earliest date from which logon events are collected.

### 2. Set the export path
```shell
$ExportPath = "C:\ActiveDirectory_Users_Last7Days.csv"
```
* The results will be saved as a CSV file at this location.

### 3. Fetch logon events (Event ID 4624)
```shell
$LogonEvents = Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4624
    StartTime = $StartDate
} -ErrorAction SilentlyContinue
```
* Event ID 4624 = Successful logon.
* Filters only security logon events after $StartDate.
* -ErrorAction SilentlyContinue ignores errors (e.g., access denied).

### 4. Process & extract event data
```shell
$ProcessedLogons = $LogonEvents | ForEach-Object {
    $xml = [xml]$_.ToXml()
    ...
}
```
* Converts each event into XML format for easier parsing.
* Extracts:

     * TargetUserName → Username
     * TargetDomainName → Domain
     * IpAddress → Source IP
     * LogonType → Type of logon (interactive, remote, network, etc.)
     * TimeCreated → Timestamp

### 5. Exclude unwanted accounts
```shell
if ($User -and -not ($User.EndsWith('$'))) {
```

* Skips:
   * Machine accounts (which end with $, e.g., SERVER01$).
   * Blank/null usernames.

### 6. Format results
```shell
[PSCustomObject]@{
    Username   = "$Domain\$User"
    LogonTime  = $Time
    IPAddress  = $IPAddress
    LogonType  = $LogonType
}
```

* Outputs data as a structured object.

### 7. Remove duplicates & sort
```shell
$DistinctLogons = $ProcessedLogons | Sort-Object Username, LogonTime -Unique
```
* Ensures unique combinations of username + logon time.

### 8. Export to CSV
```shell
$DistinctLogons | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
```
* Saves final data into a CSV file.

### 9. Completion message
```shell
Write-Host "Export complete! File saved to $ExportPath" -ForegroundColor Green
```
* Prints a confirmation message.

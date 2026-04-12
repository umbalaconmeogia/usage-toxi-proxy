# ========================================
# Client program
# ========================================

param (
    [string]$ScenarioFile = "scenario.csv",
    [int]$WaitTimeInSecond = 5
)

# ========================================
# Load Scenario File
# ========================================
if (!(Test-Path $ScenarioFile)) {
    Write-Error "Scenario file not found: $ScenarioFile"
    exit 1
}

$Scenarios = Import-Csv $ScenarioFile

Write-Host "[INFO] Scenario file: $ScenarioFile"
Write-Host "[INFO] Wait time: $WaitTimeInSecond second(s)"
Write-Host ""

# ========================================
# Helper: Timestamp
# ========================================
function Get-TimeStamp {
    return (Get-Date).ToString("yyyyMMdd HHmmss")
}

# ========================================
# Execute Scenario
# ========================================
foreach ($row in $Scenarios) {
    if ([string]::IsNullOrWhiteSpace($row.url)) { continue }

    $method  = $row.method.ToUpper()
    $url     = $row.url
    $remarks = $row.remarks

    $ts = Get-TimeStamp
    Write-Host "[$ts] Send request: $method $url"
    if ($remarks) {
        Write-Host "         Remarks: $remarks"
    }

    try {
        $response = Invoke-WebRequest `
            -Uri $url `
            -Method $method `
            -UseBasicParsing `
            -TimeoutSec 30

        $statusCode = $response.StatusCode

        if ($response.Content -is [byte[]]) {
            $body = [System.Text.Encoding]::UTF8.GetString($response.Content)
        } else {
            $body = $response.Content
        }
    }
    catch {
        if ($_.Exception.Response -ne $null) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $body = $reader.ReadToEnd()
        } else {
            $statusCode = "ERROR"
            $body = $_.Exception.Message
        }
    }

    $ts = Get-TimeStamp
    Write-Host "[$ts] Receive response: $statusCode $body"
    Write-Host ""

    Start-Sleep -Seconds $WaitTimeInSecond
}
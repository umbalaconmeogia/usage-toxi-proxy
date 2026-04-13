# ========================================
# Client program
# ========================================

param (
    [string]$ScenarioFile = "scenario.csv"
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
    $method  = if ($row.method) { $row.method.ToUpper() } else { "" }
    $url     = $row.url
    $remarks = $row.remarks
    $param   = $row.param

    if ($method -eq "WAIT") {
        $ts = Get-TimeStamp
        Write-Host "[$ts] WAIT: $param second(s)"
        if ($remarks) {
            Write-Host "         Remarks: $remarks"
        }
        Start-Sleep -Seconds ([int]$param)
        Write-Host ""
        continue
    }

    if ([string]::IsNullOrWhiteSpace($url)) { continue }

    $ts = Get-TimeStamp
    Write-Host "[$ts] Send request: $method $url"
    if ($remarks) {
        Write-Host "         Remarks: $remarks"
    }

    try {
        $webParams = @{
            Uri               = $url
            Method            = $method
            UseBasicParsing   = $true
            TimeoutSec        = 30
        }

        if ($method -eq "POST" -and $param) {
            $webParams.Add("Body", $param)
        }

        $response = Invoke-WebRequest @webParams

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
}
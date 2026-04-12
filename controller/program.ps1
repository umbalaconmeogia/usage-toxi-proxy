param (
    [string]$ScenarioFile = "toxi-scenario.csv",
    [string]$ToxiApi = "http://127.0.0.1:8474",
    [string]$ProxyName = "dataverse"
)

# ========================================
# Load Scenario
# ========================================
if (!(Test-Path $ScenarioFile)) {
    Write-Error "Scenario file not found: $ScenarioFile"
    exit 1
}

$Scenario = Import-Csv $ScenarioFile
$requestCounter = 0

Write-Host "[INFO] Loaded scenario file: $ScenarioFile"
Write-Host "[INFO] Proxy name: $ProxyName"
Write-Host "[INFO] Toxiproxy API: $ToxiApi"
Write-Host ""

# ========================================
# Utility
# ========================================
function Log($msg) {
    $ts = (Get-Date).ToString("yyyyMMdd HHmmss")
    Write-Host "[$ts] $msg"
}

# ========================================
# Toxiproxy helpers
# ========================================
function Remove-All-Toxics {
    Invoke-RestMethod -Method Get "$ToxiApi/proxies/$ProxyName/toxics" |
        ForEach-Object {
            Invoke-RestMethod -Method Delete "$ToxiApi/proxies/$ProxyName/toxics/$($_.name)"
        }
}

function Add-TimeoutToxic {
    $body = @{
        name       = "timeout_once"
        type       = "timeout"
        stream     = "downstream"
        attributes = @{ timeout = 100000 } # large timeout
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Post `
        -Uri "$ToxiApi/proxies/$ProxyName/toxics" `
        -ContentType "application/json" `
        -Body $body
}

function Add-HttpErrorToxic($status, $bodyText) {
    # truncate payload using limit_data toxic
    $payload = if ($bodyText) { $bodyText } else { "" }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload).Length

    $body = @{
        name       = "http_error"
        type       = "limit_data"
        stream     = "downstream"
        attributes = @{ bytes = 0 }
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Post `
        -Uri "$ToxiApi/proxies/$ProxyName/toxics" `
        -ContentType "application/json" `
        -Body $body
}

function Stop-Proxy {
    Log "Stopping Toxiproxy proxy: $ProxyName"
    Invoke-RestMethod -Method Post "$ToxiApi/proxies/$ProxyName/toggle" `
        -Body (@{ enabled = $false } | ConvertTo-Json)
}

# ========================================
# Main Controller Loop
# ========================================
Log "Controller started. Waiting for requests..."

while ($true) {

    Read-Host "Press ENTER when next request is detected"

    $requestCounter++

    if ($requestCounter -gt $Scenario.Count) {
        Log "No more scenario entries. Default PASS."
        continue
    }

    $row = $Scenario[$requestCounter - 1]

    $process  = $row.process.Trim()
    $response = $row.response
    $param    = $row.param

    Log "Request #$requestCounter - process=$process response=$response param=$param"

    # Clear previous toxics
    Remove-All-Toxics

    switch -Regex ($process) {
        "^\*$" {
            Log "PASS: forwarding request"
        }

        "^NONE$" {
            Log "TIMEOUT: suppress response"
            Add-TimeoutToxic
        }

        "^WAIT$" {
            Log "WAIT for $param ms"
            Start-Sleep -Milliseconds ([int]$param)
        }

        "^STOP$" {
            Stop-Proxy
            break
        }

        "^\d+$" {
            Log "HTTP ERROR $process"
            Add-HttpErrorToxic $process $response
        }

        default {
            Log "Unknown process: $process"
        }
    }
}
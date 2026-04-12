# ========================================
# Server program
# ========================================

param (
    [string]$ScenarioFile = "scenario.csv",
    [string]$BaseUrl = "http://localhost:2000",
    [int]$WaitTimeInSecond = 0
)

if (!(Test-Path $ScenarioFile)) {
    Write-Error "Scenario file not found: $ScenarioFile"
    exit 1
}
$Scenarios = Import-Csv $ScenarioFile

if (!$BaseUrl.EndsWith("/")) {
    $BaseUrl += "/"
}

$stopRequested = $false

Register-EngineEvent -SourceIdentifier ConsoleCancelEvent -Action {
    Write-Host "`n[INFO] Ctrl+C received. Stopping server..."
    $script:stopRequested = $true
} | Out-Null

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($BaseUrl)
$listener.Start()

Write-Host "[INFO] Server started at $BaseUrl"
Write-Host "[INFO] Press Ctrl+C to stop."

function Get-TimeStamp {
    (Get-Date).ToString("yyyyMMdd HHmmss")
}

try {
    while (-not $stopRequested) {
        
        # ---- ASYNC WAIT WITH SHORT TIMEOUT ----
        $task = $listener.GetContextAsync()

        while (-not $task.Wait(200)) {
            if ($stopRequested) {
                break
            }
        }

        if ($stopRequested) {
            break
        }

        $context = $task.Result
        $req = $context.Request
        $res = $context.Response

        $method = $req.HttpMethod.ToUpper()
        $path = $req.Url.AbsolutePath

        # ---- SPECIAL HANDLER: STOP SERVER ----
        if ($path -eq "/stop-server") {
            Write-Host "[$((Get-TimeStamp))] Receive request: $method $path"
            Write-Host "[$((Get-TimeStamp))] Stop request received. Server will shut down."
            $body = "SERVER STOPPED"
            $bytes = [Text.Encoding]::UTF8.GetBytes($body)
            $res.StatusCode = 200
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
            $res.Close()
            $stopRequested = $true
            continue
        }

        $matched = $Scenarios | Where-Object {
            $_.method.ToUpper() -eq $method -and $_.request -eq $path
        }

        if ($matched) {
            Write-Host "[$((Get-TimeStamp))] Receive request: $method $path"
            $body = $matched.response
        }
        else {
            Write-Host "[$((Get-TimeStamp))] Receive UNKNOWN request: $method $path"
            $body = "UNKNOWN request"
        }

        Write-Host "[$((Get-TimeStamp))] Return response: $body"

        $bytes = [Text.Encoding]::UTF8.GetBytes($body)
        $res.StatusCode = 200
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()

        if ($WaitTimeInSecond -gt 0) {
            Start-Sleep -Seconds $WaitTimeInSecond
        }
    }
}
finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    Unregister-Event ConsoleCancelEvent -ErrorAction SilentlyContinue
    Write-Host "[INFO] Server stopped immediately."
}
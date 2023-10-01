function Test-InternetConnection {

    $pingServers = @("www.google.com", "www.microsoft.com", "www.apple.com", "www.ibm.com", "www.baidu.com")
    $maxRetryCount = 3
    $retryInterval = 5
    $internetAvailable = $false

    for ($retry = 1; $retry -le $maxRetryCount; $retry++) {
        foreach ($server in $pingServers) {
            if (Test-Connection -ComputerName $server -Count 1 -Quiet) {
                $internetAvailable = $true
                break
            }
        }

        if ($internetAvailable) {
            return
        }
        else {
            Write-Host "Attempt $($retry): Internet connection is unavailable. Retrying in $retryInterval seconds..."
            Start-Sleep -Seconds $retryInterval
        }
    }
    Write-Host
    Write-Warning "Failed to establish an internet connection after $maxRetryCount attempts, script terminated."
    pause
    exit
}

function Send-Cutt {

    $Uri = "https://cutt.ly/RwbSmBPM"
    $maxRetryCount = 2
    $retryInterval = 2

    $retries = 0

    while ($retries -lt $maxRetryCount) {
        try {
            return Invoke-WebRequest -Uri $Uri -UseBasicParsing
        }
        catch {
            $retries++
            Start-Sleep -Seconds $retryInterval
        }
    }
    return $null
}

function Run-SpotX {

    param(
        $params
    )

    $maxRetryCount = 3
    $retryInterval = 5
    $url = 'https://spotx-official.github.io/SpotX/run.ps1'

    for ($retry = 1; $retry -le $maxRetryCount; $retry++) {
        try {
            $response = iwr -useb $url
            $StatusCode = $response.StatusCode
        }
        catch {
            $StatusCode = $_.Exception.Response.StatusCode.value__
        }

        if ($StatusCode -eq 200) {
            $null = Send-Cutt
            iex "& {$($response)} $params"
            return
        }
        else {
            Write-Host ("Attempt $($retry): HTTP status code: $($StatusCode). Retrying in $($retryInterval) seconds...")
            Start-Sleep -Seconds $retryInterval
        }
    }

    Write-Host
    Write-Warning "Failed to make the request after $maxRetryCount attempts, script terminated."
    pause
    exit
}

[Net.ServicePointManager]::SecurityProtocol = 3072

Test-InternetConnection

Run-SpotX -params $args

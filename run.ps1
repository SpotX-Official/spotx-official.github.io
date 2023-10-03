function Test-InternetConnection {
    function Connect {
        param (
            [string]$Domain
        )

        try {
            $tcpClient80 = New-Object System.Net.Sockets.TcpClient
            $tcpClient443 = New-Object System.Net.Sockets.TcpClient

            $tcpClient80.Connect($Domain, 80)
            $tcpClient443.Connect($Domain, 443)

            if ($tcpClient80.Connected -or $tcpClient443.Connected) {
                return $true
            }

            $tcpClient80.Close()
            $tcpClient443.Close()
        }
        catch {}

        try {
            $ping = Test-Connection -ComputerName $Domain -Count 1 -Quiet -ErrorAction Stop
            if ($ping) {
                return $true
            }
        }
        catch {}

        return $false
    }

    $domains = "www.google.com", "www.bing.com", "www.baidu.com", "yandex.com"
    $maxRetryAttempts = 3
    $retryPauseSeconds = 3
    $retryCount = 0

    do {
        $internetAvailable = $false
        foreach ($domain in $domains) {
            $result = Connect -Domain $domain
            if ($result) {
                $internetAvailable = $true
                break
            }
        }

        if ($internetAvailable) {
            break
        }

        $retryCount++
        if ($retryCount -lt $maxRetryAttempts) {
            Write-Host "Retesting in $retryPauseSeconds seconds..."
            Start-Sleep -Seconds $retryPauseSeconds
        }
        else {
            Write-Host
            Write-Warning "After $maxRetryAttempts attempts, no internet connection was detected. Exiting script."
            pause
            exit
        }
    } while ($retryCount -lt $maxRetryAttempts)
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

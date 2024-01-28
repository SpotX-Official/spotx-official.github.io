param
(
    [Alias("m")]
    [switch]$mirror
)

function Run-SpotX {

    param(
        [string]$params
    )

    $maxRetryCount = 3
    $retryInterval = 5

    if ($mirror) { 
        $url = 'https://spotx-official.github.io/SpotX/run.ps1' 
        $params += " -m"
    }
    else {
        $url = 'https://raw.githubusercontent.com/SpotX-Official/SpotX/main/run.ps1'
    }

    for ($retry = 1; $retry -le $maxRetryCount; $retry++) {
        try {
            $response = iwr -useb $url
            $StatusCode = $response.StatusCode
        }
        catch {
            $StatusCode = $_.Exception.Response.StatusCode.value__
        }

        if ($StatusCode -eq 200) {
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
    Write-Host $Error[0].Exception.Message
    pause
    exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12;
Run-SpotX -params $args
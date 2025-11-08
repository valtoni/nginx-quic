param(
    [string]$AlpineVersion,
    [string]$NginxVersion,
    [string]$MetadataPath
)

$ErrorActionPreference = 'Stop'
$headers = @{ 'User-Agent' = 'valtoni-nginx-quic-build' }

function Get-LatestGithubTagVersion {
    param(
        [Parameter(Mandatory)] [string]$Repo,
        [Parameter(Mandatory)] [string]$Pattern,
        [int]$PerPage = 100,
        [hashtable]$Headers
    )

    $uri = "https://api.github.com/repos/$Repo/tags?per_page=$PerPage"
    $tags = Invoke-RestMethod -Uri $uri -Headers $Headers
    $matches_version = foreach ($tag in $tags) {
        $match = [regex]::Match($tag.name, $Pattern)
        if ($match.Success) {
            $value = $match.Groups['version'].Value
            [pscustomobject]@{
                VersionObject = [version]$value
                VersionText   = $value
            }
        }
    }

    $latest = $matches_version | Sort-Object VersionObject | Select-Object -Last 1
    if (-not $latest) {
        throw "Unable to determine latest version for $Repo."
    }

    return $latest.VersionText
}

function Get-LatestAlpineVersion {
    param([hashtable]$Headers)
    $fullVersion = Get-LatestGithubTagVersion `
        -Repo 'alpinelinux/aports' `
        -Pattern '^v(?<version>[0-9]+\.[0-9]+\.[0-9]+)$' `
        -Headers $Headers

    $parsed = [version]$fullVersion
    return "{0}.{1}" -f $parsed.Major, $parsed.Minor
}

function Get-LatestNginxVersion {
    param([hashtable]$Headers)
    return Get-LatestGithubTagVersion `
        -Repo 'nginx/nginx' `
        -Pattern '^release-(?<version>[0-9]+\.[0-9]+\.[0-9]+)$' `
        -Headers $Headers
}

if (-not $AlpineVersion) {
    $AlpineVersion = Get-LatestAlpineVersion -Headers $headers
}

if (-not $NginxVersion) {
    $NginxVersion = Get-LatestNginxVersion -Headers $headers
}

Write-Host "Building with Alpine $AlpineVersion and NGINX $NginxVersion"

if ($MetadataPath) {
    $metadata = [pscustomobject]@{
        AlpineVersion = $AlpineVersion
        NginxVersion  = $NginxVersion
    }
    $metadata | ConvertTo-Json | Set-Content -Path $MetadataPath -Encoding UTF8
}

docker buildx build --platform linux/amd64 `
    --build-arg "ALPINE_VERSION=$AlpineVersion" `
    --build-arg "NGINX_VERSION=$NginxVersion" `
    -t valtoni/nginx-quic:${NginxVersion} . 
    #--push

param(
    [string]$AlpineVersion,
    [string]$NginxVersion,
    [string]$QuicTlsRef,
    [string]$MetadataPath
)

$ErrorActionPreference = 'Stop'
$headers = @{ 'User-Agent' = 'valtoni-nginx-quic-build' }

function Get-LatestGithubTagVersion {
    param(
        [Parameter(Mandatory)] [string]$Repo,
        [Parameter(Mandatory)] [string]$Pattern,
        [int]$PerPage = 100,
        [hashtable]$Headers,
        [string]$OutputGroup = 'version',
        [ScriptBlock]$SortKeyScript
    )

    $uri = "https://api.github.com/repos/$Repo/tags?per_page=$PerPage"
    $tags = Invoke-RestMethod -Uri $uri -Headers $Headers
    $matches_version = foreach ($tag in $tags) {
        $match = [regex]::Match($tag.name, $Pattern)
        if ($match.Success) {
            # Decide what textual value to return (defaulting to requested capture group)
            $outputValue = if ($OutputGroup -and $match.Groups[$OutputGroup].Success) {
                $match.Groups[$OutputGroup].Value
            } else {
                $tag.name
            }

            # Determine the source used for default version sorting
            $defaultSortSource = if ($match.Groups['version'].Success) {
                $match.Groups['version'].Value
            } else {
                $outputValue
            }

            # Build the sort key (custom script if provided, otherwise parsed [version])
            $sortKey = if ($SortKeyScript) {
                & $SortKeyScript $match
            } else {
                [version]$defaultSortSource
            }

            [pscustomobject]@{
                VersionObject = $sortKey
                VersionText   = $outputValue
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

function Get-LatestQuicTlsRef {
    param([hashtable]$Headers)
    return Get-LatestGithubTagVersion `
        -Repo 'quictls/openssl' `
        -Pattern '^(?<tag>openssl-(?<version>[0-9]+\.[0-9]+\.[0-9]+)\+quic(?<quic>[0-9]+))$' `
        -Headers $Headers `
        -OutputGroup 'tag' `
        -SortKeyScript {
            param($match)
            $v = [version]$match.Groups['version'].Value
            [System.Tuple]::Create(
                $v.Major,
                $v.Minor,
                $v.Build,
                [int]$match.Groups['quic'].Value
            )
        }
}

if (-not $AlpineVersion) {
    $AlpineVersion = Get-LatestAlpineVersion -Headers $headers
}

if (-not $NginxVersion) {
    $NginxVersion = Get-LatestNginxVersion -Headers $headers
}

if (-not $QuicTlsRef) {
    $QuicTlsRef = Get-LatestQuicTlsRef -Headers $headers
}

Write-Host "Building with Alpine $AlpineVersion, NGINX $NginxVersion, quictls $QuicTlsRef"

if ($MetadataPath) {
    $metadata = [pscustomobject]@{
        AlpineVersion = $AlpineVersion
        NginxVersion  = $NginxVersion
        QuicTlsRef    = $QuicTlsRef
    }
    $metadata | ConvertTo-Json | Set-Content -Path $MetadataPath -Encoding UTF8
}

docker buildx build --platform linux/amd64 `
    --build-arg "ALPINE_VERSION=$AlpineVersion" `
    --build-arg "NGINX_VERSION=$NginxVersion" `
    --build-arg "QUICTLS_REF=$QuicTlsRef" `
    -t valtoni/nginx-quic:${NginxVersion} `
    --push

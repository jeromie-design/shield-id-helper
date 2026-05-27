# Cross-compile shield-id-helper for all supported targets.
# Outputs to dist/<os>-<arch>/shield-id-helper[.exe]
#
# Requires Go toolchain on PATH. Run from this directory.

$ErrorActionPreference = 'Stop'

$targets = @(
    @{ GOOS = 'windows'; GOARCH = 'amd64'; Ext = '.exe' },
    @{ GOOS = 'darwin';  GOARCH = 'amd64'; Ext = '' },
    @{ GOOS = 'darwin';  GOARCH = 'arm64'; Ext = '' },
    @{ GOOS = 'linux';   GOARCH = 'amd64'; Ext = '' }
)

Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path dist | Out-Null

foreach ($t in $targets) {
    $dir = "dist/$($t.GOOS)-$($t.GOARCH)"
    $out = "$dir/shield-id-helper$($t.Ext)"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    $env:GOOS = $t.GOOS
    $env:GOARCH = $t.GOARCH
    $env:CGO_ENABLED = '0'

    Write-Host "Building $out ..."
    & go build -trimpath -ldflags "-s -w" -o $out .
    if ($LASTEXITCODE -ne 0) { throw "go build failed for $($t.GOOS)/$($t.GOARCH)" }
}

Remove-Item env:GOOS, env:GOARCH, env:CGO_ENABLED -ErrorAction SilentlyContinue
Write-Host "`nBuilt:" -ForegroundColor Green
Get-ChildItem -Recurse dist -File | ForEach-Object { Write-Host "  $($_.FullName)" }

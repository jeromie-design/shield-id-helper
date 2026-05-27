# Shield Identity Helper installer (Windows).
#
# Drops shield-id-helper.exe under Program Files and registers it as a Chrome
# native-messaging host so the Shield browser extension can read the OS
# hostname, LAN IP, and logged-in user.
#
# Usage (elevated PowerShell):
#   .\install.ps1 -ExtensionId <ID>
#
# Extension ID can be found at chrome://extensions with Developer mode on.
# For the published Shield extension, use the Web Store ID.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ExtensionId,

    [string]$InstallDir = "$env:ProgramFiles\CinderLabs\shield-id-helper"
)

$ErrorActionPreference = 'Stop'

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell (Run as Administrator)."
}

$exeSource = Join-Path $PSScriptRoot 'shield-id-helper.exe'
if (-not (Test-Path $exeSource)) {
    throw "shield-id-helper.exe not found next to this script. Run build.ps1 first and copy dist\windows-amd64\shield-id-helper.exe into this folder."
}

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
$exeTarget = Join-Path $InstallDir 'shield-id-helper.exe'
Copy-Item -Path $exeSource -Destination $exeTarget -Force

$manifestPath = Join-Path $InstallDir 'ai.cinderlabs.shield_identity.json'
$manifest = @{
    name            = 'ai.cinderlabs.shield_identity'
    description     = 'Shield endpoint identity helper'
    path            = $exeTarget
    type            = 'stdio'
    allowed_origins = @("chrome-extension://$ExtensionId/")
} | ConvertTo-Json -Depth 4

Set-Content -Path $manifestPath -Value $manifest -Encoding UTF8

# Register with Chrome AND Chrome-derived browsers (Edge uses its own key).
$keys = @(
    'HKLM:\Software\Google\Chrome\NativeMessagingHosts\ai.cinderlabs.shield_identity',
    'HKLM:\Software\Microsoft\Edge\NativeMessagingHosts\ai.cinderlabs.shield_identity'
)
foreach ($key in $keys) {
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name '(default)' -Value $manifestPath
}

Write-Host "Installed shield-id-helper to $exeTarget"
Write-Host "Registered native-messaging host for extension $ExtensionId"
Write-Host "Restart Chrome/Edge for the extension to pick up the helper."

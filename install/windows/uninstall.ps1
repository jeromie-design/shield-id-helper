# Shield Identity Helper uninstaller (Windows).

[CmdletBinding()]
param(
    [string]$InstallDir = "$env:ProgramFiles\CinderLabs\shield-id-helper"
)

$ErrorActionPreference = 'Continue'

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell."
}

$keys = @(
    'HKLM:\Software\Google\Chrome\NativeMessagingHosts\ai.cinderlabs.shield_identity',
    'HKLM:\Software\Microsoft\Edge\NativeMessagingHosts\ai.cinderlabs.shield_identity'
)
foreach ($key in $keys) {
    if (Test-Path $key) { Remove-Item -Path $key -Force -Recurse }
}

if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
}

Write-Host "Uninstalled shield-id-helper."

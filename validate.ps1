$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImageConfigName = "ghcr.io%2fsima-neat%2felxr%3alatest.json"
$RequiredIconTheme = "sima-ai.sima-palette-neat-product-icons"

function Pass {
  param([string]$Message)
  Write-Host "OK $Message"
}

function Fail {
  param([string]$Message)
  throw $Message
}

function Require-File {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    Fail "Missing file: $Path"
  }
  Pass "Found file: $Path"
}

function Require-Json {
  param([string]$Path)
  Get-Content -Raw $Path | ConvertFrom-Json | Out-Null
  Pass "Valid JSON: $Path"
}

function Find-CodeCli {
  $commands = @("code", "code-insiders")
  foreach ($command in $commands) {
    $found = Get-Command $command -ErrorAction SilentlyContinue
    if ($found) {
      return $found.Source
    }
  }

  $candidates = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd",
    "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd",
    "${env:ProgramFiles(x86)}\Microsoft VS Code\bin\code.cmd"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path $candidate)) {
      return $candidate
    }
  }

  return $null
}

function Get-CodeUserDir {
  if ($env:CODE_USER_DATA_DIR) {
    return Join-Path $env:CODE_USER_DATA_DIR "User"
  }

  return Join-Path $env:APPDATA "Code\User"
}

Require-File (Join-Path $RepoRoot "settings.json")
Require-File (Join-Path $RepoRoot ".devcontainer/sima-elxr/devcontainer.json")
Require-File (Join-Path $RepoRoot "product-icon-theme/package.json")
Require-File (Join-Path $RepoRoot "product-icon-theme/themes/sima-palette-neat-product-icon-theme.json")
Require-File (Join-Path $RepoRoot "product-icon-theme/source-icons/sima-logo.svg")

Require-Json (Join-Path $RepoRoot "settings.json")
Require-Json (Join-Path $RepoRoot ".devcontainer/sima-elxr/devcontainer.json")
Require-Json (Join-Path $RepoRoot "product-icon-theme/package.json")
Require-Json (Join-Path $RepoRoot "product-icon-theme/themes/sima-palette-neat-product-icon-theme.json")

$codeCli = Find-CodeCli
if (-not $codeCli) {
  Fail "VS Code CLI not found."
}

$extensions = & $codeCli --list-extensions
if ($extensions -notcontains $RequiredIconTheme) {
  Fail "VS Code extension is not installed: $RequiredIconTheme"
}
Pass "VS Code extension installed: $RequiredIconTheme"

$imageConfig = Join-Path (Join-Path (Get-CodeUserDir) "globalStorage\ms-vscode-remote.remote-containers\imageConfigs") $ImageConfigName
Require-File $imageConfig
Require-Json $imageConfig

$config = Get-Content -Raw $imageConfig | ConvertFrom-Json
$settings = $config.customizations.vscode.settings
$containerExtensions = @($config.customizations.vscode.extensions)

if ($settings."window.title" -ne "SiMa.ai Palette Neat") {
  Fail "Attached-container config has wrong window.title."
}

if ($settings."workbench.productIconTheme" -ne "sima-palette-neat-icons") {
  Fail "Attached-container config has wrong product icon theme."
}

if (-not $settings."workbench.colorCustomizations") {
  Fail "Attached-container config is missing workbench.colorCustomizations."
}

if ($containerExtensions -notcontains $RequiredIconTheme) {
  Fail "Attached-container config does not include product icon extension."
}

Pass "ELXR attached-container config contains Palette Neat settings"
Write-Host ""
Write-Host "All validation checks passed."

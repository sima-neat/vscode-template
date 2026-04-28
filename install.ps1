param(
  [switch]$SkipTerminal
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ImageConfigName = "ghcr.io%2fsima-neat%2felxr%3alatest.json"
$ImageRef = "ghcr.io/sima-neat/elxr:latest"
$Vsix = Join-Path $RepoRoot "sima-palette-neat-product-icons-0.1.0.vsix"
$TemplatePath = Join-Path $RepoRoot ".devcontainer/sima-elxr/devcontainer.json"
$IconThemeDir = Join-Path $RepoRoot "product-icon-theme"

function Write-Step {
  param([string]$Message)
  Write-Host $Message
}

function Write-Warn {
  param([string]$Message)
  Write-Warning $Message
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

function Ensure-ObjectProperty {
  param(
    [Parameter(Mandatory = $true)]$Object,
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)]$Value
  )

  if (-not $Object.PSObject.Properties[$Name]) {
    $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
  }
}

function Install-ProductIconTheme {
  if (-not (Test-Path $Vsix)) {
    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npm) {
      Write-Warn "npm not found; cannot build product icon theme VSIX. Install Node.js/npm, then rerun this installer."
      return
    }

    Write-Step "Building product icon theme VSIX..."
    New-Item -ItemType Directory -Force -Path (Join-Path $IconThemeDir "fonts") | Out-Null
    npx --yes fantasticon (Join-Path $IconThemeDir "source-icons") `
      -o (Join-Path $IconThemeDir "fonts") `
      --name sima-icons `
      --font-types woff `
      --asset-types json | Out-Null

    Push-Location $IconThemeDir
    try {
      npx --yes @vscode/vsce package --out (Join-Path ".." (Split-Path -Leaf $Vsix)) | Out-Null
    } finally {
      Pop-Location
    }
  }

  if (-not (Test-Path $Vsix)) {
    Write-Warn "Missing VSIX at $Vsix; skipping product icon theme install."
    return
  }

  $codeCli = Find-CodeCli
  if (-not $codeCli) {
    Write-Warn "VS Code CLI not found; install the VSIX manually from $Vsix."
    return
  }

  Write-Step "Installing VS Code product icon theme..."
  & $codeCli --install-extension $Vsix --force | Out-Null
}

function Get-CodeUserDir {
  if ($env:CODE_USER_DATA_DIR) {
    return Join-Path $env:CODE_USER_DATA_DIR "User"
  }

  return Join-Path $env:APPDATA "Code\User"
}

function Install-ElxrAttachConfig {
  $userDir = Get-CodeUserDir
  $imageConfigDir = Join-Path $userDir "globalStorage\ms-vscode-remote.remote-containers\imageConfigs"
  $nameConfigDir = Join-Path $userDir "globalStorage\ms-vscode-remote.remote-containers\nameConfigs"
  $imageConfigPath = Join-Path $imageConfigDir $ImageConfigName
  $nameConfigPath = Join-Path $nameConfigDir "ghcr.io-sima-neat-elxr-latest.json"

  New-Item -ItemType Directory -Force -Path $imageConfigDir | Out-Null
  New-Item -ItemType Directory -Force -Path $nameConfigDir | Out-Null

  Write-Step "Registering Palette Neat for attached container $ImageRef..."

  $template = Get-Content -Raw $TemplatePath | ConvertFrom-Json

  foreach ($configPath in @($imageConfigPath, $nameConfigPath)) {
    if (Test-Path $configPath) {
      $target = Get-Content -Raw $configPath | ConvertFrom-Json
    } else {
      $target = [PSCustomObject]@{ workspaceFolder = "/home/manuel.roldan" }
    }

    Ensure-ObjectProperty -Object $target -Name "workspaceFolder" -Value "/home/manuel.roldan"
    Ensure-ObjectProperty -Object $target -Name "settings" -Value ([PSCustomObject]@{})
    Ensure-ObjectProperty -Object $target -Name "extensions" -Value @()
    Ensure-ObjectProperty -Object $target -Name "customizations" -Value ([PSCustomObject]@{})
    Ensure-ObjectProperty -Object $target.customizations -Name "vscode" -Value ([PSCustomObject]@{})
    Ensure-ObjectProperty -Object $target.customizations.vscode -Name "settings" -Value ([PSCustomObject]@{})
    Ensure-ObjectProperty -Object $target.customizations.vscode -Name "extensions" -Value @()

    foreach ($setting in $template.customizations.vscode.settings.PSObject.Properties) {
      foreach ($settingsObject in @($target.settings, $target.customizations.vscode.settings)) {
        if ($settingsObject.PSObject.Properties[$setting.Name]) {
          $settingsObject.PSObject.Properties[$setting.Name].Value = $setting.Value
        } else {
          $settingsObject | Add-Member -MemberType NoteProperty -Name $setting.Name -Value $setting.Value
        }
      }
    }

    $extensions = @()
    $extensions += @($target.extensions)
    $extensions += @($template.customizations.vscode.extensions)
    $extensions += "sima-ai.sima-palette-neat-product-icons"
    $target.extensions = @($extensions | Where-Object { $_ } | Select-Object -Unique)

    $customExtensions = @()
    $customExtensions += @($target.customizations.vscode.extensions)
    $customExtensions += @($template.customizations.vscode.extensions)
    $customExtensions += "sima-ai.sima-palette-neat-product-icons"
    $target.customizations.vscode.extensions = @($customExtensions | Where-Object { $_ } | Select-Object -Unique)

    $target | ConvertTo-Json -Depth 100 | Set-Content -Encoding UTF8 $configPath
  }
}

function Install-TerminalExtras {
  if ($SkipTerminal -or $env:SIMA_SKIP_TERMINAL -eq "1") {
    Write-Step "Skipping terminal extras."
    return
  }

  $starship = Get-Command starship -ErrorAction SilentlyContinue
  if (-not $starship) {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
      Write-Step "Installing Starship with winget..."
      winget install --id Starship.Starship --source winget --accept-package-agreements --accept-source-agreements
    } else {
      Write-Warn "winget not found; skipping Starship install."
    }
  }

  $configDir = Join-Path $HOME ".config"
  New-Item -ItemType Directory -Force -Path $configDir | Out-Null
  Copy-Item -Force (Join-Path $RepoRoot "starship.toml") (Join-Path $configDir "starship.toml")

  $profilePath = $PROFILE.CurrentUserCurrentHost
  $profileDir = Split-Path -Parent $profilePath
  New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
  if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Force -Path $profilePath | Out-Null
  }

  $profileText = Get-Content -Raw $profilePath
  if ($profileText -notmatch "starship init powershell") {
    Add-Content -Path $profilePath -Value "`nInvoke-Expression (&starship init powershell)`n"
  }

  Write-Warn "Roboto fonts are not installed by this script on Windows. Install Roboto Mono and RobotoMono Nerd Font if VS Code falls back to Consolas."
}

Install-ProductIconTheme
Install-ElxrAttachConfig
Install-TerminalExtras

Write-Host ""
Write-Host "Done. Palette Neat will activate when VS Code attaches to $ImageRef."
Write-Host "If VS Code is already attached, run: Developer: Reload Window"

param(
  [switch]$SkipFlutterBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerScript = Join-Path $projectRoot "installer.iss"
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"
$releaseDir = Join-Path $projectRoot "build\windows\x64\runner\Release"
$installerOutput = Join-Path $projectRoot "installer\SimpleLiveSetup.exe"

function Get-PubspecVersion {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $match = Select-String -Path $Path -Pattern '^version:\s*([^\s]+)' | Select-Object -First 1
  if (-not $match) {
    throw "Could not find a version entry in pubspec.yaml."
  }

  return $match.Matches[0].Groups[1].Value
}

function Get-InnoSetupCompiler {
  $candidates = @()

  $isccCommand = Get-Command iscc -ErrorAction SilentlyContinue
  if ($isccCommand) {
    $candidates += $isccCommand.Source
  }

  $candidates += @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
  )

  return $candidates |
    Select-Object -Unique |
    Where-Object { $_ -and (Test-Path $_) } |
    Select-Object -First 1
}

Push-Location $projectRoot
try {
  if (-not (Test-Path $installerScript)) {
    throw "Missing installer script: $installerScript"
  }

  if (-not (Test-Path $pubspecPath)) {
    throw "Missing pubspec.yaml: $pubspecPath"
  }

  $pubspecVersion = Get-PubspecVersion -Path $pubspecPath
  $appVersion = ($pubspecVersion -split '\+')[0]

  $isccPath = Get-InnoSetupCompiler
  if (-not $isccPath) {
    throw "Could not find Inno Setup 6. Install ISCC.exe or add it to PATH."
  }

  Write-Host "Project version: $pubspecVersion"
  Write-Host "Installer version: $appVersion"

  if (-not $SkipFlutterBuild) {
    Write-Host "Building Windows release..."
    & flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
      throw "Flutter Windows release build failed."
    }
  }

  if (-not (Test-Path $releaseDir)) {
    throw "Missing Windows release output: $releaseDir"
  }

  Write-Host "Compiling installer with ISCC..."
  & $isccPath "/DMyAppVersion=$appVersion" $installerScript
  if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup compilation failed."
  }

  if (-not (Test-Path $installerOutput)) {
    throw "Installer was not generated at: $installerOutput"
  }

  Write-Host "Installer created:"
  Write-Host "  $installerOutput"
}
finally {
  Pop-Location
}

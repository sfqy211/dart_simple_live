param(
  [string]$Version = ""
)

$ErrorActionPreference = "Stop"

Push-Location $PSScriptRoot\..

try {
  flutter pub get
  flutter analyze --no-pub
  flutter test
  flutter build windows --release

  $pubspecVersion = (Select-String -Path "pubspec.yaml" -Pattern "^version:\s*(.+)$").Matches[0].Groups[1].Value.Trim()
  $resolvedVersion = if ($Version) { $Version } else { $pubspecVersion }

  $distDir = Join-Path (Get-Location) "dist"
  if (!(Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
  }

  $sourceDir = Join-Path (Get-Location) "build\windows\x64\runner\Release"
  $zipPath = Join-Path $distDir "simple_live_windows_v$resolvedVersion.zip"

  if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
  }

  Compress-Archive -Path (Join-Path $sourceDir "*") -DestinationPath $zipPath
  Write-Host "Release package created: $zipPath"
}
finally {
  Pop-Location
}

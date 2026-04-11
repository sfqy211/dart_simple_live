param(
  [switch]$Release
)

$ErrorActionPreference = "Stop"

Push-Location $PSScriptRoot\..

try {
  flutter pub get
  flutter analyze --no-pub
  flutter test

  if ($Release) {
    flutter build windows --release
  } else {
    flutter build windows --debug
  }
}
finally {
  Pop-Location
}

$ErrorActionPreference = "Stop"

Write-Host "== ServiZone Static Audit ==" -ForegroundColor Cyan
Write-Host "PWD: $(Get-Location)"

Write-Host "`n[1/3] flutter analyze" -ForegroundColor Yellow
flutter analyze | Tee-Object -FilePath ".\audit\out_flutter_analyze.txt"

Write-Host "`n[2/3] flutter test" -ForegroundColor Yellow
flutter test | Tee-Object -FilePath ".\audit\out_flutter_test.txt"

Write-Host "`n[3/3] Config sanity checks" -ForegroundColor Yellow
$envFile = ".\lib\config\environment_config.dart"
$manifest = ".\android\app\src\main\AndroidManifest.xml"

if (Test-Path $envFile) {
  $envContent = Get-Content $envFile -Raw
  if ($envContent -match "http://") {
    Write-Host "WARN: environment_config.dart contiene http:// (OK en dev; no recomendado en release)." -ForegroundColor DarkYellow
  }
}

if (Test-Path $manifest) {
  $m = Get-Content $manifest -Raw
  if ($m -match "usesCleartextTraffic\s*=\s*`"true`"") {
    Write-Host "WARN: AndroidManifest permite cleartext traffic. Deshabilitarlo en release." -ForegroundColor DarkYellow
  }
}

Write-Host "`nOutputs:" -ForegroundColor Green
Write-Host " - audit/out_flutter_analyze.txt"
Write-Host " - audit/out_flutter_test.txt"


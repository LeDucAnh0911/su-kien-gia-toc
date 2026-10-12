@echo off
chcp 65001 >nul
setlocal
pushd "%~dp0"
set "PATH=C:\src\flutter\bin;%PATH%"
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss-fff"') do set "RELEASE_STAMP=%%I"
if not defined RELEASE_STAMP (
  echo Khong tao duoc ten thu muc phat hanh.
  popd
  pause
  exit /b 1
)
set "RELEASE_DIR=%~dp0build\web-release-%RELEASE_STAMP%"
if exist "%RELEASE_DIR%" (
  echo Thu muc phat hanh da ton tai: %RELEASE_DIR%
  popd
  pause
  exit /b 1
)
echo Dang bien dich Flutter Web cho Su Kien Gia Toc...
flutter build web --release --no-wasm-dry-run --output "%RELEASE_DIR%"
if errorlevel 1 (
  echo Bien dich that bai. Kiem tra thong bao loi phia tren.
  popd
  pause
  exit /b 1
)
copy /Y "web\flutter_service_worker.js" "%RELEASE_DIR%\flutter_service_worker.js" >nul
if errorlevel 1 (
  echo Khong the chep Service Worker vao ban web.
  popd
  pause
  exit /b 1
)
if exist "%RELEASE_DIR%\.git" (
  echo Ban web co thu muc Git; dung phat hanh de tranh ghi de nhanh.
  popd
  pause
  exit /b 1
)
if exist "%RELEASE_DIR%\*.apk" (
  echo Ban web co APK cu; dung phat hanh de tranh phat tan goi sai.
  popd
  pause
  exit /b 1
)
echo Da tao ban Flutter Web sach trong %RELEASE_DIR%.
popd
pause

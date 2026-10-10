@echo off
chcp 65001 >nul
setlocal
pushd "%~dp0"
set "PATH=C:\src\flutter\bin;%PATH%"
echo Dang bien dich Flutter Web cho Su Kien Gia Toc...
flutter build web --release --no-wasm-dry-run
if errorlevel 1 (
  echo Bien dich that bai. Kiem tra thong bao loi phia tren.
  popd
  pause
  exit /b 1
)
copy /Y "web\flutter_service_worker.js" "build\web\flutter_service_worker.js" >nul
if errorlevel 1 (
  echo Khong the chep Service Worker vao ban web.
  popd
  pause
  exit /b 1
)
echo Da tao ban Flutter Web trong build\web.
popd
pause

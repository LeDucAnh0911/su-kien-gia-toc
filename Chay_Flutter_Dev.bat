@echo off
chcp 65001 >nul
echo ========================================================
echo   CHẠY FLUTTER Ở CHẾ ĐỘ DEV (HOT RELOAD)
echo ========================================================
echo.
set PATH=C:\src\flutter\bin;%PATH%
flutter run -d chrome
pause

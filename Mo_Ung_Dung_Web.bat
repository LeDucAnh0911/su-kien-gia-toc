@echo off
chcp 65001 >nul
echo ========================================================
echo   KHỞI ĐỘNG ỨNG DỤNG "SỔ GIỖ & LỊCH GIA TỘC"
echo ========================================================
echo.
echo Đang mở ứng dụng trên cổng 8088...
start http://localhost:8088
python -m http.server 8088 --directory "%~dp0build\web"
pause

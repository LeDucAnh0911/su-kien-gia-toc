@echo off
chcp 65001 >nul
echo ========================================================
echo   BIÊN DỊCH BẢN WEB (FLUTTER BUILD WEB) - SỔ GIỖ GIA TỘC
echo ========================================================
echo.
set PATH=C:\src\flutter\bin;%PATH%
echo Đang biên dịch Flutter Web...
flutter build web --release

if %ERRORLEVEL% EQU 0 (
    echo Đang đưa giao diện Web độc lập vào bản chạy...
    copy /Y "%~dp0standalone_web\index.html" "%~dp0build\web\index.html" >nul
    copy /Y "%~dp0standalone_web\family.js" "%~dp0build\web\family.js" >nul
    copy /Y "%~dp0standalone_web\family.css" "%~dp0build\web\family.css" >nul
    copy /Y "%~dp0standalone_web\qr_app.png" "%~dp0build\web\qr_app.png" >nul
    if exist "%~dp0So_Gio_Gia_Toc.apk" copy /Y "%~dp0So_Gio_Gia_Toc.apk" "%~dp0build\web\So_Gio_Gia_Toc.apk" >nul
    echo.
    echo ========================================================
    echo   THÀNH CÔNG! Bản web đã được cập nhật vào build\web!
    echo ========================================================
) else (
    echo.
    echo CÓ LỖI XẢY RA TRONG QUÁ TRÌNH BIÊN DỊCH WEB!
)
pause

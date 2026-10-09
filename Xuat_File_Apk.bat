@echo off
chcp 65001 >nul
echo ========================================================
echo   ĐÓNG GÓI FILE CÀI ĐẶT ANDROID (.APK) - SỔ GIỖ
echo ========================================================
echo.
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set ANDROID_HOME=C:\Android\Sdk
set PATH=C:\src\flutter\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%

echo Đang biên dịch ứng dụng sang file APK...
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo   THÀNH CÔNG! File cài đặt APK nằm tại:
    echo   %~dp0build\app\outputs\flutter-apk\app-release.apk
    echo ========================================================
    copy /y "%~dp0build\app\outputs\flutter-apk\app-release.apk" "%~dp0build\web\So_Gio_Gia_Toc.apk" >nul
    copy /y "%~dp0build\app\outputs\flutter-apk\app-release.apk" "%~dp0So_Gio_Gia_Toc.apk" >nul
    echo   Đã cập nhật file APK vào web server (cổng 8088)!
    echo.
    echo Đang mở thư mục chứa file APK...
    explorer "%~dp0build\app\outputs\flutter-apk"
) else (
    echo.
    echo Có lỗi xảy ra trong quá trình đóng gói APK!
)
pause

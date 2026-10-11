@echo off
chcp 65001 >nul
echo ========================================================
echo   ĐÓNG GÓI BẢN CÀI ANDROID (.APK) - SỰ KIỆN GIA TỘC
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
    echo   Hãy kiểm tra chứng chỉ ký và thử trên thiết bị trước khi chia sẻ.
    echo.
    echo Đang mở thư mục chứa file APK...
    explorer "%~dp0build\app\outputs\flutter-apk"
) else (
    echo.
    echo Có lỗi khi đóng gói. Cần khóa phát hành trong android\key.properties.
)
pause

@echo off
chcp 65001 >nul
echo ========================================================
echo   ĐỒNG BỘ MÃ NGUỒN VÀ TRIỂN KHAI GITHUB PAGES 24/7
echo   Ứng dụng: Sự Kiện Gia Tộc
echo ========================================================
echo.
git add .
git commit -m "Cập nhật ứng dụng Sự Kiện Gia Tộc"
echo.
echo Đang đẩy mã nguồn lên GitHub (origin main)...
git push -u origin main
echo.
echo ========================================================
echo Hoàn tất! Khi GitHub hoàn thành, website sẽ mở tại:
echo https://leducanh0911.github.io/su-kien-gia-toc/
echo ========================================================
pause

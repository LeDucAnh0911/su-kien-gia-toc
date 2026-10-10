@echo off
chcp 65001 >nul
echo ========================================================
echo   ĐỒNG BỘ MÃ NGUỒN LÊN GITHUB
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
echo Đã đẩy mã nguồn. Để cập nhật website cần biên dịch và phát hành nhánh gh-pages riêng.
echo Website hiện có tại:
echo https://leducanh0911.github.io/su-kien-gia-toc/
echo ========================================================
pause

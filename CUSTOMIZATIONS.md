# Tổng hợp các thay đổi và tối ưu hóa (Customizations & Optimizations)

Tài liệu này tổng hợp toàn bộ các chỉnh sửa, tối ưu hóa và tính năng mới đã được thực hiện trên kho lưu trữ của bạn [Kde-caelestia](https://github.com/KhanhNguyen1603/Kde-caelestia.git) dựa trên phiên bản phát hành mới nhất **v2.2.4** (`ladybug-me/caelestia-dots-kde`).

---

## 1. Tối ưu hóa hiệu năng & Tiết kiệm RAM/Pin

### 🔌 Ép Vulkan trên card đồ họa tích hợp Intel (iGPU)
* **Tệp tin ảnh hưởng:**
  * [10-autostart.sh](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/scripts/10-autostart.sh)
* **Chi tiết:** Bổ sung biến môi trường `export __NV_PRIME_RENDER_OFFLOAD=0` và `export QSG_RHI_BACKEND=vulkan` vào kịch bản khởi động autostart để ép buộc Shell **chỉ chạy phần cứng Vulkan trực tiếp trên card Intel (iGPU)**, ngăn ngừa tự động nhảy card Nvidia hay đĩa ảo rendering phần mềm, giải phóng hoàn toàn GPU Nvidia dGPU giúp laptop mát máy, tiết kiệm pin tối đa và chạy các hiệu ứng mờ (Blur) cực mượt.

---

## 2. Loại bỏ các ảnh động Anime & Dọn dẹp giao diện

### 🐱 Căn giữa Media Card & Tên bài hát 2 dòng (`Media.qml`)
* **Tệp tin ảnh hưởng:**
  * [Media.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/dashboard/dash/Media.qml)
* **Chi tiết:** 
  * Xóa bỏ hoàn toàn tệp `bongocat.gif` và khối sóng nhạc `MediaShapes` ngốn RAM.
  * Gom toàn bộ giao diện (Ảnh bìa, Tiêu đề, Ca sĩ, Album, Các nút bấm) vào thẻ chứa `Column` được **căn giữa theo chiều dọc khung hình (`anchors.verticalCenter: parent.verticalCenter`)**, giúp Media Card đẹp mắt, cân đối và xóa sạch khoảng trống dư thừa.
  * Nâng cấp tiêu đề bài hát hỗ trợ **hiển thị tối đa 2 dòng ngắt dòng tự động (`maximumLineCount: 2`, `wrapMode: Text.Wrap`)**, giúp hiển thị trọn vẹn tên bài hát dài mà không bị cụt `...` quá sớm.

### 🌸 Xóa ảnh động Anime phong cảnh (Active Window Popout)
* **Tệp tin ảnh hưởng:**
  * [ActiveWindow.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/bar/popouts/ActiveWindow.qml)
* **Chi tiết:** Loại bỏ hoàn toàn các tệp ảnh động phong cảnh pixel đổi theo thời gian (`morning.gif`, `night.gif`...) và **xóa triệt để thẻ `AnimatedImage`** ra khỏi tệp QML. QML Engine sẽ không bao giờ nạp các tệp GIF phong cảnh này vào bộ nhớ RAM ngầm.

### 🦖 Khóa cứng trò chơi Khủng Long (Loại bỏ Herta xoay tròn)
* **Tệp tin ảnh hưởng:**
  * [Visibilities.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/services/Visibilities.qml)
  * [NotifDock.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/sidebar/NotifDock.qml)
  * [DinoGame.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/sidebar/DinoGame.qml)
* **Chi tiết:** Mở lại game giải trí khi Sidebar trống thông báo. Khóa cứng thuộc tính `isCaelestiaMode = false` trong `Visibilities.qml`, mã nguồn `DinoGame.qml` đã được sửa đổi để **chỉ chạy duy nhất chú Khủng Long Pixel gốc**, loại bỏ hoàn toàn chế độ `Caelestia Mode` (chạy ảnh động anime Herta `kurukuru.gif`) và ẩn hoàn toàn thẻ gạt chế độ ở cuối sidebar (`NotifDock.qml`).

### 🚪 Xóa ảnh động trang trí trong Menu Nguồn (Power Menu)
* **Tệp tin ảnh hưởng:**
  * [Content.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/session/Content.qml)
* **Chi tiết:** Loại bỏ hoàn toàn khung ảnh động trang trí (Herta xoay/Khủng long) nằm ở giữa các nút Đăng xuất và Tắt máy, giúp menu nguồn thẳng hàng dọc tinh tế.

---

## 3. Chức năng mới & Tự động hóa

### 🔄 Chuyển hướng máy chủ kiểm tra cập nhật (Updater Redirect)
* **Tệp tin ảnh hưởng:**
  * [UpdateChecker.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/services/UpdateChecker.qml)
  * [caelestia-check-updates](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/src/bin/caelestia-check-updates)
  * [caelestia-update](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/src/bin/caelestia-update)
* **Chi tiết:** Thay thế liên kết hardcode của kho lưu trữ gốc từ `ladybug-me/caelestia-dots-kde` sang repository `KhanhNguyen1603/Kde-caelestia` để tự động kiểm tra và tải các bản cập nhật từ Fork của bạn.

### 🎵 Tối ưu hóa Trích xuất Ảnh bìa & Tìm kiếm Lời bài hát Nâng cao
* **Tệp tin ảnh hưởng:**
  * [Players.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/services/Players.qml)
  * [lyrics.hpp](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/plugin/src/Caelestia/Services/lyrics.hpp)
  * [lyrics.cpp](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/plugin/src/Caelestia/Services/lyrics.cpp)
* **Chi tiết:** 
  * **Trích xuất Youtube Thumbnail Toàn năng (`Regex`):** Sử dụng biểu thức Regex toàn năng hỗ trợ nhận diện 100% tất cả các định dạng URL của YouTube (`www.youtube.com`, `music.youtube.com`, `m.youtube.com`, `shorts`, `embed`, `youtu.be`), luôn lấy trực tiếp ảnh thumbnail gốc chất lượng cao từ YouTube.
  * **Khóa cấm iTunes API cho YouTube & Spotify:** Khóa cấm YouTube và Spotify gửi yêu cầu tra cứu sang iTunes API (vì 2 nền tảng này luôn có sẵn ảnh chính chủ), loại bỏ hoàn toàn các lỗi lấy nhầm ảnh rác iTunes khi xem video. Các trình phát nhạc địa phương (VLC, MPV, file mp3...) vẫn giữ nguyên tính năng tra cứu iTunes API khi thiếu ảnh.
  * **Bộ lọc tiêu đề thông minh (`cleanTrackTitle`):** Tự động cắt bỏ các đoạn rác nối `• Ca sĩ` (như `Mùa Don't Đến • Hanja, Dewie`), loại bỏ các cặp ngoặc `(feat...)`, `[Official Video]`, `Remix`, và các ngoặc bỏ dở do bị rút gọn `...`.
  * **Lọc tiêu đề Tạm dừng & Quảng cáo (`isPlaceholderTitle`):** Tự động nhận diện và loại bỏ các chuỗi tạm dừng trình duyệt (`Spotify - Web Player...`) và Quảng cáo (`Spotify – Advertisement`, `quảng cáo`) để giữ nguyên giao diện sạch sẽ, không tìm lời rác cho Quảng cáo.
  * **Tìm kiếm LRCLIB qua Fuzzy Search (`?q=`):** Chuyển sang dùng `?q=cleanTitle` trên LRCLIB giúp tìm kiếm chính xác các bài hát có chứa chữ số hay dấu gạch ngang (như `3107 4`, `3107-4`).
  * **Kiểm tra Thời lượng nghiêm ngặt cho LRCLIB & NetEase (`<= 1.0s`):** Bắt buộc thời lượng bài hát trên cả 2 backend LRCLIB và NetEase Music lệch không quá 1.0s (`std::abs(duration - m_duration) <= 1.0`), loại bỏ hoàn toàn việc bắt nhầm bài hát rác khi xem video.

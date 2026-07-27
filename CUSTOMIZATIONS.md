# Tổng hợp các thay đổi và tối ưu hóa (Customizations & Optimizations)

Tài liệu này tổng hợp toàn bộ các chỉnh sửa, tối ưu hóa và tính năng mới đã được thực hiện trên kho lưu trữ của bạn [Kde-caelestia](https://github.com/KhanhNguyen1603/Kde-caelestia.git) dựa trên phiên bản phát hành mới nhất **v2.2.1** (`ladybug-me/caelestia-dots-kde`).

---

## 1. Tối ưu hóa hiệu năng & Tiết kiệm RAM/Pin

### 🛠️ Sửa lỗi giải nén thô hình nền (RAM Leak 0x0 Size)
* **Tệp tin ảnh hưởng:**
  * [CachingImage.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/components/images/CachingImage.qml)
  * [WallItem.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/nexus/common/WallItem.qml)
  * [FadeImage.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/components/images/FadeImage.qml)
* **Chi tiết:** Khi chưa xác định được kích thước hiển thị (`0x0`), QML sẽ tự động giải nén ảnh gốc 4K/8K dưới dạng bitmap thô vào RAM (ngốn từ 1.0 GB đến 1.2 GB RAM). Lỗi này đã được khắc phục bằng cách ép kích thước tải mặc định về `512x512` khi layout chưa sẵn sàng.

### 🔌 Chạy Vulkan trên card đồ họa tích hợp Intel (iGPU)
* **Tệp tin ảnh hưởng:**
  * [10-autostart.sh](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/scripts/10-autostart.sh)
* **Chi tiết:** Bổ sung biến môi trường `__NV_PRIME_RENDER_OFFLOAD=0` vào kịch bản khởi động autostart để ép buộc Shell **chỉ chạy trên card Intel (iGPU)**, giải phóng hoàn toàn GPU Nvidia dGPU giúp laptop mát máy và tiết kiệm pin tối đa.

### 🖼️ Tối ưu viền ngoài mỏng tinh tế 2px (`borderconfig.hpp`)
* **Tệp tin ảnh hưởng:**
  * [borderconfig.hpp](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/plugin/src/Caelestia/Config/borderconfig.hpp)
* **Chi tiết:** Điều chỉnh độ dày viền ngoài mặc định (`thickness`) từ `10px` (bản gốc tác giả quá dày) xuống **`2px`** siêu mỏng tinh tế, giúp giao diện mượt mà và sang trọng hơn.

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

### 🎨 Trích xuất Ảnh bìa Spotify & Youtube Thumbnail, Tìm kiếm theo Tên bài hát & Tự động nhận diện Player
* **Tệp tin ảnh hưởng:**
  * [Players.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/services/Players.qml)
  * [CoverArt.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/components/widgets/CoverArt.qml)
  * [Media.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/lock/Media.qml)
  * [lyrics.cpp](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/plugin/src/Caelestia/Services/lyrics.cpp)
* **Chi tiết:** 
  * **Tự động nhận diện Player (Fix lỗi "Nothing playing"):** Nâng cấp thuật toán `Players.active` với logic `list.find(p => p.isPlaying && (p.trackTitle ?? "") !== "")`, tự động bắt chính xác Youtube Web / Spotify Web khi đang phát nhạc thay vì bị kẹt ở Spotify ngầm.
  * **Trích xuất Ảnh bìa Spotify Trực tiếp:** Nhận diện và đọc trực tiếp đường dẫn ảnh bìa từ Spotify CDN (`i.scdn.co`) trong $0\text{ms}$ không qua trung gian.
  * **Trích xuất Youtube Thumbnail Siêu nhẹ:** Tự động trích xuất Video ID từ mọi định dạng URL Youtube (`youtube.com`, `youtu.be`, `music.youtube.com`) và nạp trực tiếp ảnh `mqdefault.jpg` (320x180 px, siêu nhẹ ~10 KB), loại bỏ hoàn toàn tệp tạm rác `.org.chromium` và không bao giờ bị mất thumbnail sau 1s.
  * **Chống Cache RAM ($0\%$ RAM Leak):** Tích hợp `cache: false` và `sourceSize: Qt.size(256, 256)` vào [CoverArt.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/components/widgets/CoverArt.qml), giải phóng RAM ngay lập tức khi đổi bài, không bao giờ lưu trữ cache ảnh đĩa nhạc ngầm trong RAM.
  * **Tìm kiếm Ảnh bìa NGUYÊN BẢN CHỈ BẰNG TÊN BÀI HÁT:** Tự động tìm kiếm ảnh bìa nhỏ gọn ($100 \times 100\text{ px}$, ~6 KB) thông qua iTunes API chỉ bằng Tên bài hát/video (đã làm sạch tiêu đề), không bắt buộc phải có Ca sĩ, Album hay Thời lượng bài hát.
  * **Nhận diện Đổi bài & Nạp lời chỉ theo Tên:** Hàm `setTrack()` trong `lyrics.cpp` chỉ so sánh duy nhất tiêu đề bài hát (`t == m_title`). Đúng tên cũ thì bỏ qua, khác tên bài hát thì lập tức nạp lại lời mới (bỏ qua hoàn toàn length, artist, album).
  * **Bỏ qua chuỗi Tạm dừng Mặc định (Web Player Placeholder Filter):** Tự động bỏ qua các chuỗi tiêu đề mặc định khi tạm dừng nhạc trên trình duyệt (như `Spotify - Web Player...`, `YouTube - Web Player...`), giữ nguyên ảnh bìa và lời bài hát cũ thay vì tìm kiếm lại làm mất dữ liệu.
  * **Tìm kiếm Lời bài hát NGUYÊN BẢN CHỈ BẰNG TÊN (LRCLIB `/api/search`):** Chuyển sang tìm kiếm linh hoạt qua LRCLIB `/api/search` chỉ bằng Tên bài hát (đã tự động làm sạch các từ thừa như `[MV]`, `Official Video`, `Lyrics`...), hoàn toàn không yêu cầu Album hay Độ dài bài hát (Length/Duration).






# Tổng hợp các thay đổi và tối ưu hóa (Customizations & Optimizations)

Tài liệu này tổng hợp toàn bộ các chỉnh sửa, tối ưu hóa và tính năng mới đã được thực hiện trên kho lưu trữ của bạn [Kde-caelestia](https://github.com/KhanhNguyen1603/Kde-caelestia.git) so với phiên bản gốc (`ladybug-me/caelestia-dots-kde`).

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
  * [.bashrc](file:///home/qkhanh/.bashrc) (máy chủ)
* **Chi tiết:** Loại bỏ biến ép chạy OpenGL từ `.bashrc` và tệp autostart để khôi phục Vulkan làm backend dựng hình mượt mà nhất. Đồng thời, thêm hai biến môi trường `__NV_PRIME_RENDER_OFFLOAD=0 DRI_PRIME=0` vào kịch bản khởi động để ép buộc Shell **chỉ chạy trên card Intel (iGPU)**, giải phóng hoàn toàn GPU Nvidia dGPU giúp máy mát và tiết kiệm pin.
---

## 2. Loại bỏ các ảnh động Anime & Dọn dẹp giao diện

### 🐱 Xóa ảnh động Bongo Cat & Khối sóng nhạc (Dashboard Media)
* **Tệp tin ảnh hưởng:**
  * [Media.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/dashboard/dash/Media.qml)
* **Chi tiết:** Loại bỏ hoàn toàn tệp tin `bongocat.gif` hoạt họa cũng như hiệu ứng khối sóng nhạc hình học (`MediaShapes.qml`) ở dưới cùng của thẻ điều khiển nhạc Media. Để tránh tạo khoảng trống thừa mất cân đối, toàn bộ thông tin bài hát (ảnh bìa album, tên bài hát, ca sĩ) và các nút điều khiển nhạc đã được đặt vào một container thông minh tự động **căn giữa theo chiều dọc (vertically centered)** của widget, giúp giao diện trở nên cực kỳ gọn gàng, thanh lịch và cân đối.

### 🌸 Xóa ảnh động Anime phong cảnh (Active Window Popout)
* **Tệp tin ảnh hưởng:**
  * [ActiveWindow.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/bar/popouts/ActiveWindow.qml)
* **Chi tiết:** Loại bỏ hoàn toàn các tệp ảnh động phong cảnh pixel đổi theo thời gian (`morning.gif`, `afternoon.gif`, `evening.gif`, `night.gif`) xuất hiện khi di chuột vào widget Active Window. Đưa kích thước popout này về `0x0` để ẩn nó đi hoàn toàn.

### 🦖 Khóa cứng trò chơi Khủng Long (Loại bỏ Herta xoay tròn)
* **Tệp tin ảnh hưởng:**
  * [NotifDock.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/sidebar/NotifDock.qml)
  * [DinoGame.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/sidebar/DinoGame.qml)
* **Chi tiết:** Mở lại game giải trí khi Sidebar trống thông báo. Tuy nhiên, mã nguồn đã được sửa đổi để **chỉ chạy duy nhất chú Khủng Long Pixel gốc**, loại bỏ hoàn toàn chế độ `Caelestia Mode` (chạy ảnh động anime Herta - `kurukuru.gif`). Nút gạt chế độ ở cuối sidebar cũng đã được ẩn đi.

### 🚪 Xóa ảnh động trang trí trong Menu Nguồn (Power Menu)
* **Tệp tin ảnh hưởng:**
  * [Content.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/session/Content.qml)
* **Chi tiết:** Loại bỏ hoàn toàn khung ảnh động trang trí (Herta xoay/Khủng long) nằm ở giữa các nút Đăng xuất và Tắt máy, giúp menu nguồn thẳng hàng dọc, tinh tế và tối giản.

---

## 3. Chức năng mới & Tự động hóa

### 🔄 Chuyển hướng máy chủ kiểm tra cập nhật (Updater Redirect)
* **Tệp tin ảnh hưởng:**
  * [UpdateChecker.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/services/UpdateChecker.qml)
  * [caelestia-check-updates](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/src/bin/caelestia-check-updates)
  * [caelestia-update](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/src/bin/caelestia-update)
* **Chi tiết:** Thay thế tất cả các liên kết hardcode của kho lưu trữ gốc từ `ladybug-me/caelestia-dots-kde` sang repository của bạn `KhanhNguyen1603/Kde-caelestia`. Nhờ đó, tính năng check update tự động của hệ thống và nút **"Install Update"** trên GUI sẽ quét và tải các bản cập nhật trực tiếp từ GitHub của bạn.

### 🎵 Tối ưu hóa cơ chế nạp lời nhạc (Lyrics Anti-Spam API)
* **Tệp tin ảnh hưởng:**
  * [lyrics.cpp](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/plugin/src/Caelestia/Services/lyrics.cpp)
* **Chi tiết:** Khi bạn kéo Dashboard xuống và mở tab Media, widget QML sẽ gọi lại hàm nạp bài hát. Ở bản gốc, hàm này so sánh cả tên Album và Thời lượng bài hát cực kỳ khắt khe. Vì các phần mềm phát nhạc (như Spotify, Chrome) liên tục cập nhật hoặc thay đổi nhẹ thời lượng bài hát (lệch vài mili giây), hệ thống Caelestia lầm tưởng đây là **bài hát mới**, tự động hủy yêu cầu đang chạy, xóa sạch lời nhạc cũ và gửi API tìm kiếm mới. Lượt gửi dồn dập khiến API của LRCLIB/NetEase chặn (rate limit) hoặc báo lỗi 404. Tôi đã sửa logic C++ chỉ so sánh **Tên ca sĩ & Tên bài hát** để xác định bài hát trùng lặp, triệt tiêu 100% các yêu cầu tìm kiếm dư thừa khi mở Dashboard.

### 🙈 Hỗ trợ Ẩn tự động thông minh trên KDE Plasma (KWin Smart Auto-Hide)
* **Tệp tin ảnh hưởng:**
  * [DesktopLyrics.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/background/DesktopLyrics.qml)
  * [Visualiser.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/background/Visualiser.qml)
  * [Shimeji.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/shimeji/Shimeji.qml)
* **Chi tiết:** Thay thế giao thức gọi API độc quyền của Hyprland (vốn bị lỗi đơ và luôn báo `false` trên KDE) bằng **`ToplevelManager` của Wayland** tiêu chuẩn để tương thích hoàn toàn với trình quản lý cửa sổ KWin của KDE Plasma.
  * **Cơ chế ẩn khi Maximize:** Hệ thống tự động quét và theo dõi các cửa sổ trên màn hình. Khi bạn phóng to (maximize) bất kỳ cửa sổ ứng dụng nào (như Chrome, Konsole...) che khuất hình nền, lời nhạc, hiệu ứng sóng nhạc và cả nhân vật Shimeji sẽ tự động ẩn đi hoàn toàn. Khi bạn thu nhỏ (restore) cửa sổ lại, chúng sẽ tự động xuất hiện lại mượt mà.
  * **Tối ưu hóa hiệu năng cực cao (Lazy Evaluation):** Sự kiện quét cửa sổ chỉ được kích hoạt **khi bạn bật nút Auto-Hide trên cài đặt VÀ có nhạc đang phát**. Nếu tắt nhạc hoặc tắt nút Auto-Hide, hệ thống sẽ tự hủy liên kết theo dõi cửa sổ ngay lập tức, đưa CPU tiêu thụ về $0\%$, hoàn toàn không gây tốn tài nguyên máy ảo.

### 🎨 Tự động tìm kiếm ảnh bìa album trực tuyến (iTunes Artwork Fallback)
* **Tệp tin ảnh hưởng:**
  * [Players.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/services/Players.qml)
  * [CoverArt.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/components/widgets/CoverArt.qml)
  * [Media.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/lock/Media.qml)
* **Chi tiết:** Sửa lỗi đĩa nhạc trống trơn khi phát nhạc trên trình duyệt web (như Spotify Web). Tôi đã viết thêm tính năng **tự động tìm kiếm ảnh bìa trực tuyến** thông qua **iTunes Search API**. 
  * Khi bài hát thay đổi mà trình duyệt/phần mềm nghe nhạc không cung cấp ảnh bìa (nhưng có tên bài hát và ca sĩ), Caelestia sẽ tự động gửi một yêu cầu truy vấn đến cơ sở dữ liệu iTunes, lấy về liên kết ảnh bìa mặc định có kích thước **`100x100` pixels** nhẹ nhàng.
  * **Tối ưu hóa công cụ tìm kiếm (Smart Search Query):** 
    * **Xử lý "Unknown artist":** Khi chạy Spotify trên trình duyệt web, trình duyệt thường không nhận dạng được ca sĩ nên truyền ra tên ca sĩ mặc định là `Unknown artist`. Tôi đã viết code lọc bỏ chuỗi này ra khỏi từ khóa tìm kiếm để tránh iTunes hiểu lầm.
    * **Lọc bỏ ngoặc thừa & Từ khóa rác (Remix/Music Video):** Để tăng tính tương thích, hệ thống tự động bóc tách các chú thích trong ngoặc đơn `(...)`, ngoặc vuông `[...]` (như `(Official Video)`, `(feat. ...)`) và các từ khóa hậu tố như `remix`, `music video`, `lyric`... trong tên bài hát để đưa về tên bài hát gốc, giúp iTunes so khớp chính xác bài hát trên hệ thống của họ.
    * **Bộ nhớ đệm chống lặp (Play/Pause Query Guard):** Thiết lập biến lưu trữ tên bài hát và ca sĩ của lần tải gần nhất. Nếu trình duyệt gửi tín hiệu cập nhật giả lập khi bạn nhấn tạm dừng (Pause) hoặc phát tiếp (Play) bài hát, Caelestia sẽ tự động so sánh và bỏ qua, giữ nguyên ảnh bìa hiện tại mà không gửi thêm bất kỳ yêu cầu mạng nào lên iTunes.
  * **Tắt lưu ổ cứng (No Disk Cache):** Tôi đã thêm thuộc tính **`cache: false`** cho các thẻ hiển thị ảnh. Toàn bộ ảnh tải về sẽ được nạp tạm trực tiếp vào RAM và tự động xóa sạch ngay khi bạn chuyển bài hát, đảm bảo không bao giờ sinh ra file rác trên ổ cứng.
  * Ảnh bìa này sau đó sẽ được cập nhật phản hồi đồng thời lên cả đĩa nhạc xoay tròn ở widget Dashboard Media và màn hình khóa Lockscreen!

### 🖱️ Tối ưu hóa tương tác Click trên thanh Dock (Dock Click Behaviors)
* **Tệp tin ảnh hưởng:**
  * [Dock.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/bar/components/Dock.qml)
  * [main.js](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/src/kwin-script/contents/code/main.js)
  * [hypr_kwin_map.json](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/src/bin/hypr_kwin_map.json)
* **Chi tiết:** Bổ sung cơ chế click chuột trái thông minh, mang lại trải nghiệm giống hệt thanh taskbar gốc của KDE:
  * **Trường hợp 1 cửa sổ (Single Window):** Khi ứng dụng chỉ có duy nhất 1 cửa sổ đang mở:
    * Nếu cửa sổ **chưa được focus** (hoặc đang ẩn/minimize): Click vào biểu tượng sẽ tự động đưa cửa sổ đó lên hàng đầu và kích hoạt focus (unminimize).
    * Nếu cửa sổ **đang được focus** (đang mở và bạn đang dùng nó): Click vào biểu tượng sẽ tự động **thu nhỏ (minimize) cửa sổ đó xuống dưới** để bạn nhìn thấy các cửa sổ bên dưới.
  * **Trường hợp nhiều cửa sổ (Multiple Windows):** Khi ứng dụng có từ 2 cửa sổ trở lên:
    * Click vào biểu tượng sẽ tự động **chuyển đổi (cycle) qua từng cửa sổ một cách tuần tự** theo thứ tự từ cửa sổ thứ nhất đến cửa sổ cuối cùng rồi quay lại ban đầu. Giúp bạn chuyển đổi nhanh giữa các cửa sổ của cùng một ứng dụng (ví dụ: nhiều tab Chrome rời, nhiều cửa sổ Code) cực kỳ nhanh chóng.
  * **So sánh địa chỉ bộ nhớ nóng (Active Address Match) & Tránh cướp tiêu điểm (Focus Stealing Fix):** Để khắc phục triệt để độ trễ đồng bộ của D-Bus và hiện tượng mất focus khi click chuột vào panel của KWin, hệ thống so sánh trực tiếp địa chỉ hex đại diện (`address`) của từng cửa sổ với thuộc tính active thời gian thực `HyprlandData.activeWindow.address`.
    * **Chống cướp focus:** Trong KWin script (`main.js`), khi tiêu điểm chuyển sang các thành phần giao diện của Caelestia/Quickshell (nhận diện qua class chứa `"quickshell"`, `"caelestia"`, hoặc khớp chính xác tên lớp `"qs"`), script sẽ tự động giữ nguyên (ignore) trạng thái hoạt động của ứng dụng trước đó thay vì xóa đi, đảm bảo tính năng click-to-minimize hoạt động chính xác 100%.
    * **Theo dõi trạng thái thu nhỏ:** Script kết nối trực tiếp đến tín hiệu `minimizedChanged` của từng cửa sổ để cập nhật trạng thái ngay lập tức khi ứng dụng bị thu nhỏ hoặc phục hồi.

### 🖥️ Tiện ích Hiện màn hình nền (Show Desktop Widget)
* **Tệp tin ảnh hưởng:**
  * [ShowDesktop.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/bar/components/ShowDesktop.qml) (Mới)
  * [Bar.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/bar/Bar.qml)
  * [BarComponents.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/nexus/pages/panels/taskbar/BarComponents.qml)
  * [barconfig.hpp](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/plugin/src/Caelestia/Config/barconfig.hpp)
* **Chi tiết:** Tạo một tiện ích (Widget) mới cho thanh Taskbar có chức năng hiện nhanh màn hình nền với toggle thực sự (bấm lần 1 để ẩn, bấm lần 2 để khôi phục):
  * **Trải nghiệm đồng bộ:** Widget sử dụng icon `crop_din` (khi bình thường) và `flip_to_front` màu xanh (khi đang ở trạng thái Show Desktop), đồng điệu với phong cách Caelestia.
  * **Cơ chế hoạt động (KWin Scripting DBus):** Thay vì dùng lệnh `Show Desktop` gốc của KWin (vốn sẽ ẩn luôn cả panel Caelestia), widget tự viết một KWin script JavaScript tạm thời vào `/tmp/qs-kwin.js` rồi nạp và chạy nó qua DBus:
    * **Bấm lần 1 (Ẩn cửa sổ):** Lưu danh sách ID của các cửa sổ đang hiển thị vào bộ nhớ tạm QML, sau đó chạy script KWin để thu nhỏ (minimize) tất cả cửa sổ không phải panel (`!skipTaskbar && !desktopWindow`). Panel Caelestia **không bị ẩn**.
    * **Bấm lần 2 (Khôi phục):** Chỉ chạy script unminimize đối với các cửa sổ có ID nằm trong danh sách đã lưu. Điều này giúp bảo toàn nguyên vẹn trạng thái thu nhỏ của các cửa sổ vốn đã được thu nhỏ từ trước khi nhấn nút, hoạt động thông minh giống hệt cơ chế gốc của Windows/KDE.
  * **Tương thích KWin 5 & 6:** Script tự động kiểm tra và dùng `workspace.windowList()` (KWin 6) hoặc `workspace.clientList()` (KWin 5).
  * **Hỗ trợ Kéo-thả hoàn toàn:** Widget được đăng ký vào thư viện Taskbar Components, người dùng có thể tùy ý kéo-thả sắp xếp vị trí hoặc bật/tắt nó trong trang Cài đặt (Nexus > Taskbar > Toggle & rearrange).

> **⚠️ Lưu ý CachyOS (và các distro Arch-based):**
> - CachyOS mặc định dùng **Fish shell** (không phải Bash). Các lệnh kiểm thử DBus phải chạy trên **1 dòng duy nhất** trong Konsole, hoặc dùng `bash -c "..."` để chạy bash inline.
> - CachyOS dùng **`qdbus6`** (Qt6) thay vì `qdbus`. Lệnh đúng để tương tác với KWin:
>   ```bash
>   qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript /path/to/script.js
>   qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.start
>   ```
> - Code trong QML đã dùng `qdbus6` mặc định, không cần chỉnh sửa thêm.

### 🔗 Nút "Ghim / Tạo lối tắt ra màn hình" (Pin to Desktop / Create Symlink Shortcut) & Tối giản Launcher
* **Tệp tin ảnh hưởng:**
  * [AppItem.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/launcher/items/AppItem.qml)
* **Chi tiết:** Kết hợp tính năng Pin to Desktop mới nhất của Upstream v2.1.5 với cơ chế tạo symlink tiết kiệm dung lượng của bạn:
  * **Biểu tượng ghim (`push_pin`):** Thay thế nút dấu cộng cũ và nút con mắt (Hide App) bằng duy nhất một nút ghim `push_pin` đặt bên trái nút Trái tim yêu thích.
  * **Tự động nhận diện trạng thái (`isPinned`):** Sử dụng đối tượng `Process` trong QML để kiểm tra thời gian thực xem ứng dụng đã có liên kết/file trên thư mục `~/Desktop` hay chưa. Nút `push_pin` sẽ sáng màu khi ứng dụng đã được ghim.
  * **Cơ chế Bật/Tắt ghim (Toggle Pin/Unpin):**
    * **Bấm lần 1 (Ghim):** Tự động tạo một **liên kết mềm (symbolic link - `ln -sf`)** từ tệp `.desktop` gốc của ứng dụng ra `~/Desktop/`. Cách này giữ nguyên ưu điểm không làm tốn dung lượng ổ đĩa và tự động cập nhật khi ứng dụng nâng cấp.
    * **Bấm lần 2 (Bỏ ghim):** Tự động xóa liên kết mềm (`rm -f`) khỏi thư mục `~/Desktop/`.
  * **Tối ưu hóa căn chỉnh:** Định vị nút Trái tim sát lề phải, nút Ghim kế bên, và căn chỉnh độ co giãn chữ ứng dụng về `90px` để phần tên và mô tả ứng dụng có nhiều không gian hiển thị nhất.

### ⚡ Hàng nút nguồn nhanh ở App Launcher (Launcher Quick Session Row)
* **Tệp tin ảnh hưởng:**
  * [Content.qml](file:///home/qkhanh/Code/Kde%20caelestia/caelestia-dots-kde/shell/modules/launcher/Content.qml)
* **Chi tiết:** Thêm một hàng nút nằm ngang dưới cùng ở Trình khởi chạy ứng dụng (App Launcher) để thao tác nhanh các tính năng hệ thống:
  * **Hàng nút bao gồm:** Đăng xuất (Log Out), Ngủ (Sleep), Khởi động lại (Restart), Tắt máy (Shut Down).
    * **Chi tiết lệnh hoạt động:**
      * **Log Out (Đăng xuất):** Gọi lệnh DBus chính thống của KDE `["sh", "-c", "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null"]` để đảm bảo hệ thống thực hiện graceful logout (không bị lỗi đen màn hình như khi ép loginctl tắt ngang).
      * **Sleep (Ngủ tạm):** Gọi lệnh C++ bản địa `["suspend"]`.
      * **Restart (Khởi động lại):** Gọi lệnh C++ bản địa `["reboot"]`.
      * **Shut Down (Tắt máy):** Gọi lệnh C++ bản địa `["poweroff"]`.
  * **Đồng bộ phong cách Caelestia:** Nút bấm được thiết kế tinh tế với bo góc `Tokens.rounding.medium` của Caelestia, hiển thị dạng thẻ tự động đổi màu khi hover (`Colours.palette.m3surfaceContainerHigh` và `Low`). Cấu trúc Layout tự động co giãn đều theo chiều ngang của bảng.
  * **Đóng tự động & Đảm bảo luồng chạy (Execution Order Fix):** Khi nhấn nút, hệ thống sẽ thực thi lệnh gọi hệ thống **trước**, sau đó mới thực hiện hành động đóng Launcher (`root.visibilities.launcher = false`). Việc này nhằm ngăn chặn lỗi QML Engine hủy nạp (unload) Launcher quá nhanh trước khi tiến trình gọi DBus/C++ kịp bắt đầu, đảm bảo lệnh Đăng xuất/Sleep/Restart/Shutdown luôn được gửi đi thành công 100%.





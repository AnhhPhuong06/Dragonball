# Build IPA unsigned bằng GitHub Actions

Workflow `.github/workflows/ios-unsigned.yml` build trực tiếp trên
runner macOS của GitHub, dùng Xcode 16.4. Không cần certificate,
provisioning profile hoặc cài lại Unity cho bản export này.

Workflow tự chạy khi push lên `main`. Để chạy lại thủ công:

1. Mở [Actions của repo](https://github.com/AnhhPhuong06/Dragonball/actions).
2. Chọn **Build unsigned iOS IPA** → **Run workflow** → nhánh `main`.
3. Đợi job **Build unsigned IPA** hoàn tất.
4. Trong trang build, tải artifact **Dragonball-unsigned-ipa**.
   Giải nén file ZIP tải về để lấy `Dragonball-unsigned.ipa`.

Artifact **xcodebuild-log** chứa log Xcode và được upload cả khi
bước build lỗi. Các artifact được giữ 14 ngày.

GitHub Actions tải ba thư viện `.a` bằng Git LFS khi checkout.
GitHub Actions và Codemagic dùng chung `scripts/build-unsigned-ipa.sh`
để build Release cho thiết bị iOS rồi đóng gói `Payload/Dragonball.app`.
Nếu đổi tên app, tên IPA sẽ tự đổi theo sản phẩm build.

IPA chưa ký; cần ký lại trước khi cài trên iPhone thông thường.

Tài liệu chính thức:

- [Checkout và Git LFS](https://github.com/actions/checkout)
- [Upload artifacts](https://github.com/actions/upload-artifact)
- [Runner macOS 15](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)

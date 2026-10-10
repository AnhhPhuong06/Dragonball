# Build IPA unsigned trên Codemagic

Dự án là bản export iOS từ Unity 2021.3.45f2, dùng IL2CPP và arm64.
Thư viện đã có sẵn nên workflow không cần cài Unity, Unity license,
CocoaPods, certificate hay provisioning profile.

## Đưa cấu hình vào repo hiện có

- Đặt `codemagic.yaml` ở **thư mục gốc của repo**.
- Đặt `.gitattributes` và `.gitignore` cùng các file export iOS.
  Nếu ghép vào repo đã có các file này, thêm các quy tắc vào file hiện có.
- Giữ đầy đủ `Classes`, `Data`, `Libraries`, `MainApp`, `Unity-iPhone`,
  `Unity-iPhone.xcodeproj`, `UnityData.xcassets`, `UnityFramework`,
  các file `LaunchScreen*`, `Info.plist` và các file export khác.
- Nếu project nằm trong thư mục con, workflow tự tìm khi chỉ có một
  `Unity-iPhone.xcodeproj`. Có thể đặt rõ `XCODE_PROJECT` trong YAML,
  ví dụ `Mod/IOS/Unity-iPhone.xcodeproj`.

`Libraries/libiPhone-lib.a` khoảng 328 MiB, vượt giới hạn 100 MiB của
GitHub. File `.gitattributes` đã cấu hình Git LFS cho tất cả `*.a`.
Tại clone Git của repo hiện có, chạy trước khi commit các file export:

```powershell
git lfs install --local
git add .
git commit -m "Add Codemagic unsigned iOS workflow"
git push
```

Nếu các thư viện đã được theo dõi bằng Git thường, chạy từ gốc repo
để chuyển bản hiện tại sang LFS, sau đó commit và push:

```powershell
git add --renormalize .
git commit -m "Track iOS static libraries with Git LFS"
git push
```

Lệnh `--renormalize` không chuyển các commit cũ sang LFS. Nếu GitHub
từ chối push vì file lớn trong lịch sử, cần xử lý lịch sử đó riêng.
Không upload thư viện qua giao diện web GitHub; cần push bằng Git LFS.

## Chạy trên Codemagic

1. Kết nối repo trong **Add application** nếu chưa kết nối.
2. Chọn nhánh đã push cấu hình, bấm **Check for configuration file**.
3. Bấm **Start new build**, chọn workflow **Unity iOS - Unsigned IPA**
   (`ios-unsigned`) và bắt đầu build.
4. Khi build thành công, tải `Dragonball-unsigned.ipa` trong **Artifacts**.
   Log Xcode cũng được lưu thành artifact `xcodebuild.log`.

Workflow dùng macOS M2 và Xcode 16.4, build Release cho thiết bị iOS,
tắt code signing và bitcode, sau đó đóng gói `.app` thành
`Payload/Dragonball.app` bên trong IPA. Nếu tên app thay đổi, tên IPA
sẽ tự thay đổi theo app đã build.

IPA này chưa ký. Cần ký lại bằng công cụ sideload trước khi cài
trên iPhone thông thường; không dùng trực tiếp để upload App Store.

## Kiểm tra và xử lý lỗi

- `Missing Unity library`: kiểm tra đã push đủ thư mục `Libraries`.
- `Invalid library`: file đang là con trỏ LFS hoặc không phải thư viện;
  kiểm tra upload LFS, quyền truy cập và log bước `git lfs pull`.
- `Set XCODE_PROJECT`: đặt đúng đường dẫn project trong repo.
- Build/compile/link lỗi: xem dòng `error:` đầu tiên trong artifact
  `xcodebuild.log`; việc tắt code signing không xử lý lỗi mã nguồn.

Cấu hình đã được chuẩn bị trên Windows. Cần chạy workflow trên
Codemagic để xác nhận biên dịch và tạo IPA thực tế.

Tài liệu chính thức:

- [Cấu hình YAML](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)
- [Git LFS](https://docs.codemagic.io/knowledge-git/accessing-git-lfs/)
- [Máy build Xcode 16.4](https://docs.codemagic.io/specs-macos/xcode-16-4/)

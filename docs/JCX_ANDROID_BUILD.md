# JCX Android 無人值守版本

本變更以 `aappa777/rustdesk` 的 `53996e3c404ea5083df0775057e4149e49102084` 為基底。

## 首次啟動設定

- 僅適用 Android。首次啟動且設定目錄內沒有 `RustDesk.toml` 與 `RustDesk2.toml` 時，透過 `Config::set_permanent_password` 設定永久密碼 `JcxPos@2026`，沿用上游的加鹽雜湊與加密儲存機制。
- 設定 `verification-method = use-permanent-password`，不接受隨機臨時密碼。
- 設定 `approve-mode = password`，使用密碼驗證的連入不需另按接受。
- 設定 `allow-remote-config-modification = Y`，允許已連入且具控制權的連線修改設定。
- 沒有指定自架伺服器，因此沿用上游伺服器設定；不寫入佔位網址。
- 既有安裝不會被重設；首次初始化後，使用者變更或清除的密碼與權限不會在重開時被恢復。升級既有 RustDesk 安裝時，需自行設定永久密碼。

固定密碼包含在原始碼與 APK 中，所有新安裝共用此密碼，部署後可在設定中更換。
Android 的無障礙、螢幕擷取及背景執行授權仍須由裝置使用者允許；本變更不會自動授予系統權限或自動啟動分享服務。

## GitHub Actions 編譯

1. 將本分支合併或補丁套用至儲存庫預設分支 `master`，並推送至 GitHub。
2. 如果 fork 尚未啟用 Actions，先在 Actions 頁面啟用工作流。
3. 選擇 **Actions → Build Android APK → Run workflow**。
4. 執行成功後，在該次執行的 **Artifacts** 下載 `rustdesk-arm64-v8a-apk`，解壓縮取得 `rustdesk-arm64-v8a.apk`。

也可使用已具該儲存庫寫入權限的 GitHub CLI 帳號：

```powershell
gh workflow run build-android-apk.yml --repo aappa777/rustdesk --ref master
gh run list --repo aappa777/rustdesk --workflow build-android-apk.yml --limit 5
# 將下方 RUN_ID 替換為上一行顯示的執行編號。
gh run download RUN_ID --repo aappa777/rustdesk --name rustdesk-arm64-v8a-apk
```

新工作流僅建置 ARM64 Android APK，重用上游的 bridge 工作流與 Android 建置工具版本。
不發佈 GitHub Release。APK artifact 保存 14 天。首次建置包含 Rust、Flutter 與原生依賴，完成時間依快取與排程而定，不能保證 10–15 分鐘。

### APK 簽章

若儲存庫已設定以下上游相容的 Actions secrets，工作流會使用該金鑰重新簽章：

- `ANDROID_SIGNING_KEY`：Base64 編碼的 keystore。
- `ANDROID_ALIAS`
- `ANDROID_KEY_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`

未設定時仍會輸出以該次 runner 的 debug key 簽署的 release APK。
這個簽章通常無法覆蓋官方版本或不同 runner 建置的版本；持續部署應設定固定簽章金鑰。
解除安裝會清除設定與裝置 ID，請先備份必要資料。

## 驗證與影響範圍

已檢查首次啟動的 Flutter 與 JNI 入口均在設定目錄就緒後、啟動伺服器前初始化。
已使用 actionlint 檢查新增工作流，並檢查 shell 語法與補丁格式。
本機尚未執行完整 Rust/Android 編譯，也尚未進行實機連線驗收。

既有檔案僅修改 `src/lib.rs` 與 `src/flutter_ffi.rs`：前者註冊 Android 專用模組，後者在 Flutter 啟動與 JNI 服務啟動時呼叫初始化。
這兩個入口皆可能啟動 Android 核心，因此兩處都需涵蓋。Windows、macOS、Linux、iOS 的初始化路徑不變。
新增 `src/android_defaults.rs` 與 `.github/workflows/build-android-apk.yml`；不修改共用 `hbb_common` submodule 或既有發佈工作流。

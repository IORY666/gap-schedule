# Gap 任务日历 · iOS IPA 全自动构建

## 你只需要 3 步

### 1. 推到 GitHub
```bash
cd D:\GapSchedule
git init
git add -A
git commit -m "Gap iOS App"
git remote add origin https://github.com/你的用户名/仓库名.git
git push -u origin main
```

### 2. GitHub 自动开始构建
推送后，GitHub Actions 自动在 **macOS 云端** 运行：
- 安装 xcodegen → 生成 Xcode 项目
- xcodebuild → 编译 Swift 代码
- 打包 → 生成 IPA 文件

**3-5 分钟后**，到 GitHub 仓库的 Actions 页面下载 IPA。

### 3. 安装到 iPhone
下载 IPA 后，用以下任一工具安装（免费，无需开发者账号）：
- **AltStore**（推荐）：电脑装 AltServer → 连手机 → 拖入 IPA
- **Sideloadly**：电脑连手机 → 拖入 IPA → 输入 Apple ID
- 每 7 天自动重签（连同一 WiFi 即可）

## 项目结构
```
D:/GapSchedule/
├── .github/workflows/build-ios.yml   ← 云端构建脚本
├── iOS/
│   ├── project.yml                    ← xcodegen 项目配置
│   ├── GapSchedule/                   ← Swift 源代码
│   │   ├── GapScheduleApp.swift
│   │   ├── ContentView.swift
│   │   ├── Models/TaskData.swift
│   │   ├── Views/（3个视图文件）
│   │   ├── Managers/（3个管理器）
│   │   └── Info.plist
│   └── README.md
├── desktop_widget.pyw                 ← Windows 桌面版
├── gap-schedule.html                  ← 浏览器版
└── voice/                             ← 语音文件
```

## 可选：手动触发
在 GitHub Actions 页面点 "Run workflow" 按钮即可随时重新构建。

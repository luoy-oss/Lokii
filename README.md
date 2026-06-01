# Lokii 记账

一个现代化的记账应用，具有苹果设计风格，适用于 Android 和桌面平台。

## 功能特性

- 📝 **快速记账** - 打开应用直接进入记账页面，快速记录收支
- 🏷️ **智能标签** - 支持最近使用标签和自定义标签，快速标记账目
- 📊 **月度统计** - 饼图展示分类占比，清晰了解消费结构
- 📈 **年度统计** - 柱状图展示月度趋势，掌握全年收支情况
- 🔍 **分类查看** - 点击分类查看该分类下的所有账目
- 🌙 **深色模式** - 支持浅色/深色主题切换
- 📤 **数据导出** - 导出全部数据为 JSON 文件
- 📥 **数据导入** - 从 JSON 文件导入数据（自动备份）
- 💾 **备份恢复** - 自动备份 + 手动恢复，防止数据丢失
- 🗑️ **账目删除** - 左滑删除或编辑页删除，支持确认对话框

## 技术栈

- **框架**: Flutter 3.24.5
- **语言**: Dart
- **数据库**: SQLite (sqflite)
- **状态管理**: Provider
- **图表**: fl_chart
- **文件选择**: file_picker

## 安装运行

### 1. 安装 Flutter SDK

```bash
# Windows (使用 Git Bash)
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 或者使用 VS Code 扩展: Flutter
```

### 2. 克隆项目

```bash
git clone https://github.com/luoy-oss/Lokii.git
cd Lokii
```

### 3. 生成平台目录

```bash
# 首次需要生成平台目录（已 gitignore）
flutter create --project-name lokii --platforms android,windows,linux,macos .
```

### 4. 安装依赖并运行

```bash
flutter pub get
flutter run
```

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用配置和主题
├── models/                      # 数据模型
│   ├── transaction.dart         # 账目模型（含 JSON 序列化）
│   ├── category.dart            # 分类模型
│   └── tag.dart                 # 标签模型
├── database/                    # 数据层
│   ├── db_helper.dart           # SQLite 数据库管理
│   └── data_repository.dart     # 数据仓库（导入/导出/备份/恢复）
├── providers/                   # 状态管理
│   ├── transaction_provider.dart
│   ├── category_provider.dart
│   └── settings_provider.dart
├── screens/                     # 页面
│   ├── home_screen.dart         # 首页（记账页面）
│   ├── add_transaction_screen.dart
│   ├── statistics_screen.dart   # 统计页面
│   ├── category_detail_screen.dart
│   ├── settings_screen.dart     # 设置页面
│   └── tag_manage_screen.dart
├── widgets/                     # 可复用组件
│   ├── transaction_tile.dart
│   ├── quick_tag_selector.dart
│   ├── stat_chart.dart
│   ├── category_icon.dart
│   ├── month_picker.dart
│   └── tag_chip.dart
└── utils/                       # 工具类
    ├── constants.dart           # 常量定义
    ├── theme.dart               # 苹果风格主题
    └── formatters.dart          # 格式化工具
```

## 数据管理

### 导出数据
设置 → 数据管理 → 导出数据

导出为 JSON 文件，包含所有账目、标签、分类。

### 导入数据
设置 → 数据管理 → 导入数据

从 JSON 文件导入数据，**会覆盖现有数据**。导入前自动备份。

### 恢复备份
设置 → 数据管理 → 恢复备份

支持两种方式：
- 从自动备份恢复（按时间列表选择）
- 从外部备份文件恢复

## 下载安装

从 [GitHub Releases](https://github.com/luoy-oss/Lokii/releases) 下载对应平台的安装包：

| 平台 | 说明 |
|------|------|
| Android | 下载 APK 直接安装 |
| Windows | 解压 zip 后运行 `lokii.exe` |
| Linux | 解压 tar.gz 后运行 `lokii` |
| macOS | 解压 zip 后运行 `Lokii.app` |

## 开发说明

### 添加新分类
编辑 `lib/utils/constants.dart` 中的 `AppCategories` 类。

### 修改主题
编辑 `lib/utils/theme.dart` 中的 `AppTheme` 类。

### 构建发布
```bash
# 分析代码
flutter analyze lib/

# 构建 Windows
flutter build windows --release --no-tree-shake-icons

# 构建 Android
flutter build apk --release --no-tree-shake-icons
```

## License

MIT License

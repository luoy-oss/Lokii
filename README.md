# Lokii 记账

一个现代化的记账应用，具有苹果设计风格，适用于小米手机。

## 功能特性

- 📝 **快速记账** - 打开应用直接进入记账页面，快速记录收支
- 🏷️ **智能标签** - 支持最近使用标签和自定义标签，快速标记账目
- 📊 **月度统计** - 饼图展示分类占比，清晰了解消费结构
- 📈 **年度统计** - 柱状图展示月度趋势，掌握全年收支情况
- 🔍 **分类查看** - 点击分类查看该分类下的所有账目
- 🔔 **自动记账** - 读取支付宝、微信支付通知自动记录（可选）
- 📤 **数据导出** - 支持导出为 CSV 文件，方便备份和分析
- 🌙 **本地存储** - 所有数据存储在本地，保护隐私安全

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **数据库**: SQLite (sqflite)
- **状态管理**: Provider
- **图表**: fl_chart
- **国际化**: intl

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
git clone <repository-url>
cd Lokii
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 运行应用

```bash
# 连接手机或启动模拟器后
flutter run
```

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用配置和主题
├── models/                      # 数据模型
│   ├── transaction.dart         # 账目模型
│   ├── category.dart            # 分类模型
│   └── tag.dart                 # 标签模型
├── database/                    # 数据库操作
│   ├── db_helper.dart           # SQLite 数据库管理
│   └── export_helper.dart       # CSV 导出功能
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
├── services/                    # 服务层
│   └── notification_service.dart
└── utils/                       # 工具类
    ├── constants.dart           # 常量定义
    ├── theme.dart               # 苹果风格主题
    └── formatters.dart          # 格式化工具
```

## 自动记账功能

自动记账功能需要授权通知监听权限：

1. 打开应用 → 设置 → 自动记账
2. 开启"通知自动记账"开关
3. 系统会提示授权通知监听权限
4. 授权后，应用会自动解析支付宝、微信支付通知并记录

**支持的通知格式**:
- 支付宝: "您在XXX消费XX元"
- 微信支付: "微信支付收款¥XX"

## 数据导出

支持导出为 CSV 文件，包含以下字段：
- 日期
- 类型（收入/支出）
- 分类
- 金额
- 标签
- 备注
- 是否自动记录

导出的文件可以通过系统分享功能发送到其他应用。

## 开发说明

### 添加新分类

编辑 `lib/utils/constants.dart` 中的 `AppCategories` 类。

### 修改主题

编辑 `lib/utils/theme.dart` 中的 `AppTheme` 类。

### 自动记账规则

编辑 `lib/services/notification_service.dart` 中的解析规则。

## License

MIT License

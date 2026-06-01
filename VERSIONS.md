# 版本兼容性记录

本文档记录 Lokii 项目已验证可用的工具版本组合。

## ✅ 当前稳定版本组合（2025-06 验证通过）

| 工具 | 版本 | 说明 |
|------|------|------|
| **Flutter** | `3.24.5` | 稳定版，全平台构建通过 |
| **Dart** | `3.5.4` | Flutter 3.24.5 内置 |
| **Gradle** | `9.1.0` | `flutter create` 自动生成 |
| **Android SDK** | `34` | Flutter 3.24.5 默认 |
| **JDK** | `17` | GitHub Actions 默认 |
| **Xcode** | 最新稳定版 | macOS runner 自带 |
| **Visual Studio** | 2022 | Windows runner 自带 |

### CI 环境

| 平台 | Runner | 状态 |
|------|--------|------|
| Android (arm64/armv7/x86_64) | `ubuntu-latest` | ✅ |
| Windows (x64) | `windows-latest` | ✅ |
| Linux (x64) | `ubuntu-latest` | ✅ |
| macOS (universal) | `macos-latest` | ✅ |

### 已知不兼容的版本

| Flutter 版本 | 问题 |
|-------------|------|
| `3.29.x` | `CardThemeData`/`DialogThemeData` 不存在 |
| `3.32.x` | Gradle 插件 `fileMode` 与 Gradle 9.x 不兼容 |
| `3.44.0` | 生成的平台文件与 3.24.5 不兼容 |

### 关键依赖版本

```yaml
# pubspec.yaml 中的依赖
dependencies:
  sqflite: ^2.3.0
  sqflite_common_ffi: ^2.3.0
  provider: ^6.1.1
  fl_chart: ^0.66.0
  file_picker: ^8.0.0
  shared_preferences: ^2.2.2
  uuid: ^4.2.1
  csv: ^5.1.1
  intl: 由 flutter_localizations 自动管理（不显式声明）
```

### 主题兼容性

Flutter 3.24.5 支持的主题属性：
- ✅ `AppBarTheme`
- ✅ `DividerThemeData`
- ✅ `SnackBarThemeData`
- ✅ `TextTheme`
- ✅ `ColorScheme.fromSeed()`
- ❌ `CardThemeData`（3.24.5 不存在）
- ❌ `DialogThemeData`（3.24.5 不存在）
- ❌ `NavigationBarThemeData`（3.24.5 不存在）
- ❌ `BottomSheetThemeData`（3.24.5 不存在）
- ❌ `FilledButtonThemeData`（3.24.5 不存在）

### 平台目录说明

平台目录（`android/`、`ios/`、`linux/`、`macos/`、`windows/`、`web/`）已加入 `.gitignore`。

**原因**：不同 Flutter 版本生成的平台文件不兼容，CI 会在构建时用 `flutter create --project-name lokii --platforms <平台>` 重新生成。

**本地开发**：首次需要运行：
```bash
flutter create --project-name lokii --platforms android,windows,linux,macos .
```

## 更新版本检查清单

如果需要升级 Flutter 版本：

1. [ ] 本地安装目标 Flutter 版本
2. [ ] 运行 `flutter create --project-name lokii --platforms android,windows,linux,macos .`
3. [ ] 运行 `flutter pub get`
4. [ ] 运行 `flutter analyze lib/`（确认 0 error）
5. [ ] 运行 `flutter build windows --release --no-tree-shake-icons`（或目标平台）
6. [ ] 检查 `CardThemeData`/`DialogThemeData` 等 API 是否可用
7. [ ] 更新 `.github/workflows/build-release.yml` 中的 `FLUTTER_VERSION`
8. [ ] 更新本文档

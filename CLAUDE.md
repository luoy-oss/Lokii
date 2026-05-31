# CLAUDE.md - Lokii 项目开发规范

## 项目概述
Lokii 是一个现代化记账应用，使用 Flutter 开发，具有苹果设计风格。

## 版本管理规范

### 版本号格式
采用语义化版本 `vMAJOR.MINOR.PATCH`：
- **MAJOR**: 重大功能变更、架构调整、不兼容的 API 修改
- **MINOR**: 新增功能、较大改进（如新增页面、新增统计维度）
- **PATCH**: Bug 修复、UI 微调、性能优化、文案修改

### 版本类型判断

| 变更类型 | 版本 | 示例 |
|---------|------|------|
| 新增页面/功能模块 | MINOR | `v1.1.0` |
| 修复已有功能的 Bug | PATCH | `v1.0.1` |
| UI 样式微调/优化 | PATCH | `v1.0.2` |
| 重构代码（无功能变化） | PATCH | `v1.0.3` |
| 添加新依赖/更新依赖 | PATCH | `v1.0.4` |
| 重大架构变更 | MAJOR | `v2.0.0` |

### 发布流程

每次代码完善后，执行以下步骤：

1. **修改版本号** — 更新 `pubspec.yaml` 中的 `version` 字段（格式：`x.y.z+build`）
2. **提交代码** — `git add -A && git commit -m "type: 描述"`
3. **打标签** — `git tag v{MAJOR}.{MINOR}.{PATCH}`
4. **推送** — `git push origin master && git push origin v{MAJOR}.{MINOR}.{PATCH}`

### 提交信息规范

格式：`type: 简短描述`

| type | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复 Bug |
| `ui` | UI/样式调整 |
| `refactor` | 重构 |
| `perf` | 性能优化 |
| `deps` | 依赖变更 |
| `docs` | 文档更新 |
| `chore` | 构建/工具变更 |

### 自动构建

推送 `vX.Y.Z` 格式的标签后，GitHub Actions 自动构建并发布以下平台的安装包：
- Android APK（ARM64、ARMv7、x86_64）
- Windows（x64 zip）
- Linux（x64 tar.gz）
- macOS（app zip）

**注意**：`vX.Y.Z-beta`、`vX.Y.Z-alpha`、`vX.Y.Z-pre` 等预发布标签不会触发自动构建。

## 开发规范

### 代码风格
- 使用 2 空格缩进
- 遵循 Dart 官方 lint 规则
- 组件使用 `const` 构造函数（当可能时）
- 使用 `AppTheme` 上下文辅助方法而非硬编码颜色

### 文件组织
- `lib/models/` — 数据模型
- `lib/database/` — 数据库和导出
- `lib/providers/` — 状态管理
- `lib/screens/` — 页面
- `lib/widgets/` — 可复用组件
- `lib/utils/` — 工具和主题
- `lib/services/` — 服务层

### 测试
构建前运行：
```bash
flutter analyze lib/
```

### 发布前检查清单
- [ ] `flutter analyze` 无 error
- [ ] 在 Windows 桌面端测试基本功能
- [ ] 确认 `pubspec.yaml` 版本号已更新
- [ ] 确认 CHANGELOG 已更新（如有）

# 正则助手 (Regex Helper)

用中文自然语言生成正则表达式，支持 **Windows** 和 **安卓**。

## 功能

- **中文描述生成正则**：本地规则引擎，离线可用。
  - `匹配11位手机号` → `1[3-9]\d{9}`（自动加锚定）
  - `提取邮箱地址` → `[\w.+-]+@[\w-]+(?:\.[\w-]+)+`
  - `6-16位字母和数字` → `[a-zA-Z0-9]{6,16}`
  - 支持手机号、邮箱、身份证、IP、网址、日期、时间、金额、QQ、微信、车牌、邮编、用户名、密码、中文、数字、字母、空白等类型
- **正则测试器**：输入文本实时高亮匹配结果，支持忽略大小写/多行模式。
- **常用模板库**：60+ 常用正则，按分类浏览、一键复制、一键测试。
  - 包含 **流放之路2（POE2）** 简体/繁体通货、装备、宝石、符文、地图等模板。
- **AI 生成（可选）**：接入任意 OpenAI 兼容接口（OpenAI / DeepSeek / 通义千问等），理解更复杂的自然语言。API Key 仅保存在本机。
- 生成结果一键复制、一键跳转测试。

## 构建

环境要求：Flutter SDK 3.x，Android 需 JDK 17+ 与 Android SDK。

### 安卓（APK）

```bash
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk
# 安装到手机：adb install build/app/outputs/flutter-apk/app-release.apk
```

### Windows（桌面应用）

Windows 桌面版需在 Windows 机器上构建（Flutter 不支持在 Linux 交叉编译 Windows）。产出的 exe **不依赖 Flutter 环境**，目标电脑双击即可运行。

**方式一：GitHub Actions（推荐，无需在本机装 Flutter）**

仓库已内置 `.github/workflows/build.yml`。把代码推送到 GitHub 后：

1. 在 Actions 页面手动运行 **Build Windows & Android**，或在推送 `v*` 标签时自动触发
2. 构建完成后下载 **regex-helper-windows** 构件，解压后双击 `regex_helper.exe` 即用
3. 安卓 APK 在同一工作流的 **regex-helper-android** 构件中

**方式二：本机构建（需要 Windows + Flutter）**

1. 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) 并启用 Windows 桌面支持：
   ```bash
   flutter config --enable-windows-desktop
   ```
2. 在本目录执行：
   ```bash
   flutter pub get
   flutter build windows
   # 输出：build/windows/x64/runner/Release/regex_helper.exe
   ```
3. 分发时把整个 `Release` 文件夹拷给对方（exe + data 目录）。若目标电脑提示缺少
   msvcp140.dll，安装微软「Visual C++ 运行库」或在同目录放上该 dll。
4. 开发调试：`flutter run -d windows`

### 其他平台调试

```bash
flutter run -d linux   # Linux 桌面（需 libgtk-3-dev）
flutter test           # 运行单元测试
flutter analyze        # 静态检查
```

## AI 配置

1. 打开应用 → 右上角设置
2. 开启「启用 AI 生成」，填写 API 地址、API Key、模型名
3. 兼容 OpenAI 接口的服务均可：
   - OpenAI：`https://api.openai.com/v1`，`gpt-4o-mini`
   - DeepSeek：`https://api.deepseek.com/v1`，`deepseek-chat`
   - 通义千问：`https://dashscope.aliyuncs.com/compatible-mode/v1`，`qwen-plus`

## 离线说明

不配置 AI 也能完整使用：本地规则引擎 + 模板库完全离线。AI 仅作为可选的增强。

## 目录结构

```
lib/
  main.dart                 # 应用入口
  models/                   # 数据模型
  engine/regex_engine.dart  # 本地规则引擎（中文 → 正则）
  data/
    templates.dart          # 常用模板
    poe2_templates.dart     # 流放之路2 简繁模板
  services/
    settings_service.dart   # 设置持久化（shared_preferences）
    ai_service.dart         # AI 生成（OpenAI 兼容）
  screens/
    home_screen.dart        # 生成器主页
    tester_screen.dart      # 正则测试器
    templates_screen.dart   # 模板库
    settings_screen.dart    # 设置
  widgets/match_highlight.dart  # 匹配高亮组件
```

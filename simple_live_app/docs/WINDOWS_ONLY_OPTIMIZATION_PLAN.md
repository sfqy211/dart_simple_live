# Windows Only Optimization Plan

## Goal

本计划用于将当前项目进一步收敛为一个更稳定、可维护、以 Windows 桌面观看为中心的版本。

目标不是继续堆功能，而是按优先级处理以下问题：

- 稳定性
- 可维护性
- 性能
- Windows-only 瘦身
- 依赖风险

## Scope

当前计划默认只覆盖 `simple_live_app`，重点关注：

- 直播间主链路
- 浮窗/幽灵窗口
- 字幕识别
- 弹幕与聊天
- 设置系统
- 依赖与基础设施

## Priority Tiers

### P0: 必须优先处理

这些问题会直接影响项目继续维护的成本、运行风险或用户数据安全。

1. 敏感日志脱敏
   状态: `completed`
   说明:
   - 当前本地存储读取和写入日志会直接打印完整值。
   - 包括 Bilibili Cookie 在内的敏感字段不应出现在控制台和日志文件中。
   目标:
   - 对 Cookie、Token、Authorization、API Key、密码类字段统一脱敏。
   - 保留足够调试信息，但默认不输出完整敏感值。

2. 直播间主链路拆分第一阶段
   状态: `planned`
   说明:
   - `live_room_controller.dart`、`ghost_window.dart`、`player_controller.dart` 等文件体量过大。
   - 当前播放器、字幕、弹幕、窗口模式、聊天输入耦合较深。
   目标:
   - 先抽出低风险能力模块。
   - 降低单文件复杂度，减少回归范围。

3. 停更依赖替换预备
   状态: `completed`
   说明:
   - `flutter_easyrefresh` 已 discontinued。
   - 当前只使用其基础刷新/加载能力，具备替换条件。
   目标:
   - 明确替换方案。
   - 完成基础列表容器的去耦准备。

4. 播放器抽象边界建立
   状态: `planned`
   说明:
   - 当前大量逻辑直接耦合 `media_kit`。
   - 后续如需试验 `fvp` 或更换内核，迁移成本很高。
   目标:
   - 先建立播放器适配边界，不立即切换播放器实现。

### P1: 高优先级优化

这些问题不一定马上出错，但会明显拖慢后续开发。

1. 设置系统分层
   状态: `planned`
   说明:
   - `app_settings_controller.dart` 体量过大，聚合了过多领域设置。
   目标:
   - 按播放、弹幕、字幕、窗口、同步拆分设置读写职责。

2. Windows-only 依赖清理第二阶段
   状态: `completed`
   说明:
   - 继续检查 `share_plus`、`dynamic_color`、`network_info_plus`、`device_info_plus` 等依赖是否值得保留。
   目标:
   - 删除无价值依赖。
   - 尽量减少插件层复杂度和构建风险。

3. 列表容器统一
   状态: `completed`
   说明:
   - `PageGridView` 和 `PageListView` 结构相近，有重复逻辑。
   目标:
   - 统一错误态、空态、刷新态和加载更多策略。

4. 日志系统分级
   状态: `in_progress`
   说明:
   - 现在调试信息较多，且输出控制不够精细。
   目标:
   - 区分开发日志、文件日志、敏感日志。
   - 默认降低噪音输出。

### P2: 中优先级优化

1. 同步模块与主链路继续解耦
   状态: `planned`

2. 直播页性能剖面优化
   状态: `planned`
   方向:
   - rebuild 范围缩小
   - 高频状态流降噪
   - 长时间观看稳定性检查

3. UI 组件抽象补齐
   状态: `planned`
   方向:
   - 直播页顶部/底部控制条
   - 设置项行组件
   - 统一操作面板容器

4. 低风险依赖升级
   状态: `planned`
   方向:
   - 仅升级补丁版和低风险小版本
   - 不主动进行大版本破坏性升级

### P3: 后续储备项

1. 播放器内核 POC
   状态: `planned`
   方向:
   - `media_kit` 与 `fvp` 做 Windows-only A/B 验证

2. 测试补齐
   状态: `planned`
   方向:
   - 设置迁移
   - 直播页基础进入流程
   - 字幕开关
   - 浮窗切换

3. 构建与发布流程整理
   状态: `planned`
   方向:
   - 打包脚本
   - 发布产物规范
   - 版本说明流程

## Execution Strategy

第一阶段直接执行以下顺序：

1. 修复敏感日志问题
2. 更新文档状态
3. 提交 git
4. 处理第一个低风险结构优化点
5. 再次验证并提交 git

## Progress Log

- `2026-04-11`: 建立 Windows-only 优化计划文档，等待并行分析结果后开始执行第一批改造。
- `2026-04-11`: 完成第一批 P0/P1 优化：统一日志脱敏、请求头脱敏、去掉登录流程明文 Cookie 日志、为本地设置写入增加“值未变化则不写入”的短路逻辑、移除未使用的 `dynamic_color` 依赖。
- `2026-04-11`: 完成第二批 P0/P1 优化：移除已停更的 `flutter_easyrefresh`，引入项目内 `PagedRefreshContainer`，统一列表页首刷、下拉刷新与触底加载行为。
- `2026-04-11`: 完成第三批 P1 优化：移除 `share_plus` 与 `url_launcher`，将日志导出替换为 Windows 资源管理器定位，将外链打开收口为 Windows-only 本地 helper，进一步减少插件层复杂度。

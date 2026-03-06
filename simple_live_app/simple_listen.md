# Simple Live 项目深度分析与“纯净黑听”开发方案

## 第一部分：项目深度分析

### 1. 目录结构与模块划分

项目采用典型的 Flutter + GetX 架构，核心逻辑分离为 `app` (UI/业务) 和 `core` (底层协议) 两个包。

```
dart_simple_live/
├── simple_live_app/ (主应用)
│   ├── lib/
│   │   ├── app/ (全局配置, Utils, Styles)
│   │   ├── models/ (数据模型, Hive实体)
│   │   ├── modules/ (业务模块 - GetX Pattern)
│   │   │   ├── live_room/ (核心直播间: Player + Danmaku)
│   │   │   ├── home/ (首页)
│   │   │   ├── mine/ (个人中心)
│   │   │   └── ...
│   │   ├── requests/ (Dio 封装)
│   │   ├── services/ (全局服务: Account, DB, Settings)
│   │   └── widgets/ (通用组件)
│   └── pubspec.yaml (依赖管理)
└── simple_live_core/ (核心协议库)
    ├── lib/
    │   ├── src/
    │   │   ├── interface/ (Site/Danmaku 接口定义)
    │   │   ├── danmaku/ (各平台弹幕协议实现)
    │   │   ├── model/ (通用数据模型)
    │   │   └── *_site.dart (各平台 API 实现)
    └── pubspec.yaml
```

### 2. 技术栈分析

*   **框架**: Flutter (Dart)
*   **状态管理**: GetX (路由、依赖注入、状态更新)
*   **网络**: Dio (REST API), WebSocket (弹幕), Protobuf (部分弹幕协议)
*   **播放器**: `media_kit` (基于 mpv, 性能极强, 跨平台)
*   **存储**: Hive (NoSQL, 用于配置、历史、关注列表)
*   **窗口管理**: `window_manager` (桌面端窗口控制)
*   **弹幕渲染**: `canvas_danmaku` (高性能绘制)

### 3. 核心运行机制

*   **直播流获取**:
    1.  `LiveRoomController` 调用 `LiveSite.getRoomDetail` (在 `simple_live_core` 中实现)。
    2.  `BiliBiliSite` 等实现类请求平台 API，解析出真实流地址 (`LivePlayUrl`)。
    3.  `PlayerController` 将 URL 喂给 `media_kit` 的 `Player` 实例。

*   **弹幕系统**:
    1.  `LiveRoomController` 获取弹幕连接信息 (`serverHost`, `token` 等)。
    2.  调用 `LiveSite.getDanmaku()` 获取对应的 `LiveDanmaku` 实例 (如 `BiliBiliDanmaku`)。
    3.  `BiliBiliDanmaku` 建立 WebSocket 连接，接收二进制数据，解析为 `LiveMessage`。
    4.  通过 Stream 将消息分发给 UI，`CanvasDanmaku` 组件进行渲染。

*   **账户体系**:
    *   `BiliBiliAccountService` 管理 Cookie 持久化 (Hive)。
    *   目前主要用于获取高清流 (1080P+)，**发送弹幕功能尚未实现**。

---

## 第二部分：“纯净黑听”二次开发方案 (Detailed)

基于对 `Bilibili-Live-Spamer.js` 的深度逆向分析及项目代码审查，制定以下详细实施方案。

### 阶段一：身份与交互 (发送弹幕)

**目标**: 实现 B 站直播间发送弹幕功能，确保高成功率与低风控风险。

#### 1. 核心协议逆向与实现 (`simple_live_core`)

根据脚本分析，B站弹幕发送接口具有严格的格式要求，需在 `BiliBiliSite` 类中新增 `sendDanmaku` 方法。

*   **API 接口**: `POST https://api.live.bilibili.com/msg/send`
*   **Content-Type**: `multipart/form-data` (关键：普通 JSON 或 FormUrlEncoded 可能会失败)
*   **Header 要求**:
    *   `Cookie`: 必须包含 `bili_jct` (CSRF Token) 和 `SESSDATA`。
    *   `User-Agent`: 建议伪装为 Web 端或标准移动端 UA。
*   **请求参数详解**:

| 参数名 | 类型 | 必填 | 示例值/说明 |
| :--- | :--- | :--- | :--- |
| `roomid` | String | 是 | 直播间真实 ID (`realRoomId`) |
| `msg` | String | 是 | 弹幕内容 |
| `csrf` | String | 是 | Cookie 中的 `bili_jct` 值 |
| `csrf_token` | String | 是 | 同 `csrf` (双重验证，必须同时存在) |
| `rnd` | String | 是 | 当前时间戳 (秒级, `DateTime.now().millisecondsSinceEpoch ~/ 1000`) |
| `color` | String | 否 | `16777215` (白色), 高级弹幕需 VIP |
| `fontsize` | String | 否 | `25` (默认) |
| `mode` | String | 否 | `1` (普通弹幕) |
| `bubble` | String | 否 | `0` |
| `room_type` | String | 否 | `0` |
| `jumpfrom` | String | 否 | `0` |
| `reply_mid` | String | 否 | `0` |
| `reply_attr` | String | 否 | `0` |
| `replay_dmid` | String | 否 | `0` |
| `statistics` | String | 否 | `{"appId":100,"platform":5}` (模拟 Web 端来源) |

#### 2. 服务层适配 (`simple_live_app`)

*   **Cookie 解析**: 在 `BiliBiliAccountService` 中添加逻辑，从持久化的 Cookie 字符串中正则提取 `bili_jct`。
    ```dart
    // 伪代码逻辑
    String? get csrfToken => RegExp(r"bili_jct=(.*?);").firstMatch(cookie)?.group(1);
    ```
*   **发送方法封装**:
    *   方法签名: `Future<bool> sendMsg(String roomId, String msg)`
    *   逻辑:
        1.  检查是否登录。
        2.  获取 `csrfToken`。
        3.  调用 `BiliBiliSite.sendDanmaku`。
        4.  处理返回结果 (code 0 为成功，其他为错误码，如 10030/10031 为触发风控或禁言)。

#### 3. UI 交互设计 (`LiveRoomPage`)

*   **输入入口**:
    *   移动端: 底部工具栏新增“发送”图标，点击弹出 `BottomSheet` 或键盘上方的输入条。
    *   桌面端: 播放器底部常驻半透明输入框 (类似 B 站 Web 端全屏模式)。
*   **快捷键**: 桌面端监听 `LogicalKeyboardKey.enter`，在输入框获焦时触发发送。
*   **本地回显**:
    *   原因: B 站弹幕服务器推送存在 1-3 秒延迟，且可能丢包。
    *   实现: 发送请求成功后，立即在本地构造一个 `LiveMessage` 对象（包含当前用户信息），通过 `danmakuController.addDanmaku()` 直接插入屏幕，提供流畅体验。

### 阶段二：核心“黑听”逻辑 (纯音频模式)

**目标**: 仅播放音频，极大降低资源占用 (GPU 解码率降至 0)。

#### 1. 播放器内核调整 (`PlayerController`)

利用 `media_kit` (基于 mpv) 的底层能力实现“无视频轨道”播放。

*   **方案 A (推荐)**: 设置 `vo` (Video Output) 为 `null`。
    *   代码: `player.platform.setProperty('vo', 'null')`
    *   效果: 解码器完全停止视频流处理，仅解复用音频流。
    *   恢复: 切换回正常模式时设为 `gpu` 或 `libmpv`。
*   **方案 B**: 禁用视频轨道。
    *   代码: `player.setVideoTrack(VideoTrack.no())`
    *   注意: 需验证部分直播流在无视频轨道时是否会自动断开。

#### 2. 界面伪装 (UI Layer)

*   **AudioModeCover 组件**:
    *   触发条件: `isAudioOnlyMode == true`
    *   层级: 位于 `VideoView` 之上，`DanmakuView` 之下 (保证弹幕依然可见)。
    *   **视觉元素**:
        *   背景: 纯黑 (`Colors.black`)，适配 OLED 屏幕省电。
        *   中心: UP 主头像 (圆形，带呼吸灯效果/阴影)。
        *   信息: 显示直播间标题、当前热度/在线人数。
        *   频谱 (可选): 使用 `lottie` 加载一个简单的音频跳动动画。

### 阶段三：平台特性适配 (后台与小窗)

**目标**: 实现真正的“挂机”与“伴随式”体验。

#### 1. Android 后台保活 (核心难点)

Flutter 应用进入后台后，Engine 可能会被挂起。

*   **解决方案**: 使用 `flutter_background_service` + `audio_session`。
*   **实现步骤**:
    1.  **配置 Service**: 在 `AndroidManifest.xml` 中注册 `ForegroundService`。
    2.  **音频焦点**: 配置 `AudioSession` 为 `speech` 或 `music`，申请音频焦点，防止被其他应用打断。
    3.  **通知栏控制**: 创建一个常驻通知 (Notification)，显示：
        *   标题: 直播间名称
        *   副标题: UP 主名称
        *   按钮: 播放/暂停，停止 (关闭 Service)。
    4.  **生命周期管理**: 在 App `paused` (后台) 状态下，确保 `Player` 实例不被销毁。

#### 2. Windows 托盘与透明模式

*   **托盘集成 (`system_tray`)**:
    *   功能: 点击关闭按钮不退出 App，而是最小化到托盘。
    *   菜单: 右键托盘图标 -> 显示/隐藏，退出。
*   **透明“幽灵”模式**:
    *   场景: 边写代码边看弹幕。
    *   实现:
        1.  窗口去边框: `windowManager.setTitleBarStyle(TitleBarStyle.hidden)`
        2.  背景透明: `windowManager.setBackgroundColor(Colors.transparent)`
        3.  窗口置顶: `windowManager.setAlwaysOnTop(true)`
        4.  内容隐藏: 隐藏除弹幕层以外的所有 UI (包括黑听模式的头像背景)，只保留文字。
        5.  鼠标穿透 (可选，视 `window_manager` 支持情况): 让鼠标点击穿透到下层应用，纯粹作为“弹幕蒙版”使用。

### 阶段四：任务拆解与执行计划

| 阶段 | 任务ID | 模块 | 任务详细描述 | 依赖 | 预估工时 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **P1** | T1-1 | Core | 在 `BiliBiliSite` 实现 `sendDanmaku`，含 Multipart 封装与参数签名 | 无 | 2h |
| | T1-2 | App | 在 `BiliBiliAccountService` 实现 CSRF 提取与鉴权逻辑 | T1-1 | 1h |
| | T1-3 | UI | 开发 `ChatInputWidget`，适配软键盘与桌面回车键 | T1-2 | 3h |
| **P2** | T2-1 | Player | 封装 `toggleAudioMode`，实现 mpv 属性动态切换 | 无 | 2h |
| | T2-2 | UI | 开发 `AudioModeCover` 遮罩层与 UI 联动 | T2-1 | 2h |
| **P3** | T3-1 | Android | 集成前台服务，处理音频焦点与通知栏 | 无 | 4h |
| | T3-2 | Windows | 集成托盘图标与窗口透明化逻辑 | 无 | 3h |

### 验收标准

1.  **功能性**:
    *   **弹幕**: 任意 B 站直播间发送弹幕，Web 端可见；本地列表立即显示，无卡顿。
    *   **黑听**: 开启后画面消失（显示头像），声音继续；任务管理器显示 GPU 使用率显著下降。
    *   **后台**: Android 锁屏 30 分钟以上，直播声音不中断，通知栏可控制暂停。
2.  **稳定性**:
    *   弱网环境下发送弹幕失败应有 Toast 提示，不崩溃。
    *   长时间挂机（2小时+）内存无明显泄漏。
3.  **兼容性**:
    *   Windows 10/11 正常运行。
    *   Android 10+ 正常运行前台服务。

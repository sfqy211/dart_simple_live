# 弹幕同步功能研究

> 本文档记录弹幕云同步功能的技术研究和方案设计。

---

## 竞品分析

### danmakus-client

**项目地址**: https://github.com/81f9db2ec2/danmakus-client

TypeScript 编写的 B 站弹幕客户端，基于 Tauri 桌面框架。核心库 `danmakus-core` 可作为独立库或 CLI 使用。

**去重策略**:
```typescript
const MESSAGE_DEDUP_WINDOW_MS = 2_000;    // 2秒去重窗口
const MESSAGE_DEDUP_CACHE_LIMIT = 4_000;  // 缓存上限

// 去重 key: roomId:cmd:raw
isDuplicateIncomingMessage(message: DanmakuMessage): boolean {
  const dedupKey = this.buildIncomingMessageDedupKey(message);
  // 检查是否在2秒窗口内已存在
}
```

**局限性**: 仅处理单客户端接收 Bilibili 广播时的重复弹幕，不处理多用户上传场景。

---

### dd-center

**组织地址**: https://github.com/dd-center

该组织维护多个 VTuber 相关项目，其中 `bilibili-vtuber-live-danmaku-relay` 是 WebSocket 转发服务，不做去重，仅转发 Bilibili 广播事件。

---

## 核心问题：多用户上传去重

### 问题描述

当多个用户观看同一直播间并上传弹幕时，会产生重复数据。例如：
- 用户 A 和用户 B 同时观看同一房间
- Bilibili 服务器广播同一条弹幕给所有观众
- A 和 B 都上传到服务端 → 重复

### 解决方案

使用内容哈希去重。哈希生成公式：

```
hash = MD5("${roomId}_${uid}_${timestamp}_${message}")
```

**为什么四元组足够唯一**：
- `roomId`: 区分不同直播间
- `uid`: 区分不同用户
- `timestamp`: Bilibili 服务器时间戳，同一用户同一秒内不会发两条相同消息
- `message`: 消息内容

**为什么不用 raw 字段**：
- raw 是完整协议包，包含客户端本地时间等不稳定字段
- 不同客户端解析后内容可能不一致

---

## 弹幕消息字段对照

### Flutter LiveMessage（当前）

```dart
class LiveMessage {
  final LiveMessageType type;   // 消息类型
  final String userName;        // 用户名
  final String message;         // 弹幕内容
  final dynamic data;           // 附加数据
  final LiveMessageColor color; // 颜色
  // 缺少 uid 和 timestamp
}
```

### Bilibili 原始 DANMU_MSG

```json
{
  "cmd": "DANMU_MSG",
  "info": [
    [0, 4, 25, "16777215"],      // [flag, mode, fontsize, color]
    "弹幕内容",                    // [1] 消息
    [123456, "用户名", ...],      // [2] 用户信息: [uid, uname, ...]
    [1700000000, 0, 0, "..."]   // [0][4] timestamp, 其他字段
  ]
}
```

### 字段映射

| 用途 | Bilibili 原始字段 | LiveMessage 目标字段 |
|------|------------------|-------------------|
| 用户标识 | `info[2][0]` | `uid: String` |
| 发送时间 | `info[0][4]` (Unix 秒) | `timestamp: int` |
| 用户名 | `info[2][1]` | `userName: String` |
| 弹幕内容 | `info[1]` | `message: String` |
| 颜色 | `info[0][3]` | `color: LiveMessageColor` |

---

## 实现方案

### Flutter 端改动

1. **修改 `LiveMessage` 模型**
   - 添加 `uid` 字段
   - 添加 `timestamp` 字段

2. **修改弹幕解析代码**
   - 从 `info[2][0]` 提取 uid
   - 从 `info[0][4]` 提取 timestamp

3. **新增 `DanmakuSyncService`**
   - 定时上传（每 5 分钟）
   - 内存缓冲区批量发送
   - 用户开关控制

### Vue 服务端改动

1. **新增 `POST /api/sync/danmaku` 接口**
   - 接收批量弹幕
   - 服务端哈希去重
   - 存储到 MySQL

2. **数据库表设计**
```sql
CREATE TABLE danmaku (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  hash VARCHAR(64) UNIQUE NOT NULL,  -- 去重索引
  room_id BIGINT NOT NULL,
  uid VARCHAR(32),
  user_name VARCHAR(128),
  message TEXT,
  timestamp INT,                      -- Bilibili 时间戳
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_room_time (room_id, timestamp),
  UNIQUE INDEX idx_hash (hash)
);
```

---

## 用户提示设计

开启同步时的提示内容：

```
开启弹幕同步后将自动同步以下内容到云端：
• 每 5 分钟上传一次弹幕记录
• SC (醒目留言) 记录
• 礼物记录
• 相同内容会自动去重，不会重复存储
• 可随时在设置中关闭
• 当前登录的 B 站账号信息仅用于身份验证
```

---

## 参考项目

- [danmakus-client](https://github.com/81f9db2ec2/danmakus-client) - 去重策略参考
- [dd-center](https://github.com/dd-center) - bilibili-vtuber-live-danmaku-relay
- [vdb - VTuber Database](https://github.com/dd-center/vdb) - VTuber 数据聚合

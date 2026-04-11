# Player Kernel POC

## Goal

在不切换现有播放器实现的前提下，对 Windows-only 场景下的播放器内核替换成本做一次可执行评估。

## Current Baseline

- 当前实现：`media_kit + media_kit_video + media_kit_libs_video`
- 已完成的边界准备：
  - [player_engine.dart](C:/Users/sfqy/Documents/code/dart_simple_live/simple_live_app/lib/modules/live_room/player/player_engine.dart)
  - `PlayerController` 不再直接负责播放器创建与主流订阅绑定

## Candidates

### media_kit

优点：
- 当前项目已稳定运行
- 支持现有截图、音量、播放列表、日志监听和 Windows 自定义输出参数
- 迁移成本最低

缺点：
- 仍然依赖 MPV 相关日志与渲染兼容处理
- 某些渲染失败场景需要额外 fallback

### fvp

优点：
- Windows-only 场景下有继续评估价值
- 理论上可以减少一部分 MPV 侧兼容逻辑

缺点：
- 现有项目依赖的能力需要重新核对：
  - 截图
  - 自定义输出驱动
  - 详细状态读取
  - 播放器日志订阅
  - 当前直播页的控制链路
- 切换成本明显高于当前收益

## Conclusion

当前阶段不建议切换内核。

建议结论：
- 继续保留 `media_kit`
- 先通过 [player_engine.dart](C:/Users/sfqy/Documents/code/dart_simple_live/simple_live_app/lib/modules/live_room/player/player_engine.dart) 维持播放器边界
- 如果后续出现明确的 Windows 播放稳定性瓶颈，再单独开分支做 `fvp` A/B 验证

## Exit Criteria

本 POC 以“边界建立 + 替换成本评估完成”为完成标准，不要求本阶段引入第二套播放器实现。

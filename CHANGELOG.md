# Changelog

## 0.1.1 — 2026-11-09

首次公开发布／First public release. The runtime is the same v0.1.1 implementation validated on November 7, 2026.

- 原生 UMG 压力面板：Raw、Tier、七个维度、玩家状态及最近事件；F3 显隐，F4 重载。
- Native UMG HUD for Raw tension, Tier, seven dimensions, player state and recent outcomes; F3 toggles visibility and F4 reloads it.
- 包含实战版已有的兼容修复：按原生地址识别对象、弱引用 Map 使用 `Find` 读取、世界切换时重建并验证控件，以及使用 `dofile` 避开模块缓存问题。
- Includes the existing runtime fixes for native-address identity, weak-key map reads through `Find`, widget validation/rebuilding across world changes, and module-cache-compatible `dofile` loading.
- 中英文说明、实战截图、可复用的 PowerShell 发行包脚本。
- Chinese/English documentation, an actual HUD screenshot and a reusable PowerShell package script.

验证／Validation: UE4SS prerequisite 1.0.3, Steam build 26367565, 斧老大·彭猛; 34 retained samples, Raw -44.1954 to 100, no mod runtime errors in the validation log after the first successful sample. F3/F4 and death/re-entry were checked. Runtime files are unchanged by publication packaging.

限制／Limits: recent events show positive/negative results and profile **base weights**, not final weighted contributions. Rate and confidence are game-returned fields. The HUD is Chinese; other builds and all encounters are not exhaustively verified.

许可／License: [BossTensionDisplay Source-Available License 1.0](LICENSE), adapted from `iiiiiie/esp`. This is not MIT or an OSI-approved open-source license. Sale is prohibited; the `wanjiadongli.com` / 玩家动力 operators/controllers, Bilibili UID `1317077696` operators/controllers and related parties defined in LICENSE receive no project license. Attribution, free distribution and source-sharing conditions apply to permitted redistribution. See LICENSE for the complete terms and platform boundary.

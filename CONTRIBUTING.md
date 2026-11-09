# Contributing

请先阅读 [LICENSE](LICENSE)。本项目使用自定义源码公开许可证；被排除主体不获许可。主动提交贡献表示你有权提交，并同意该贡献按当前 LICENSE 发布、修改和再分发，具体见第6条。

Read [LICENSE](LICENSE) before contributing. This is a custom source-available project, with excluded parties and no-sale/source-sharing conditions. By submitting a contribution, you confirm your right to submit it and agree to the contribution terms in Section 6.

## Reports and changes

- 报告问题时提供模组版本、游戏 build、UE4SS 前置版本、复现步骤及预期／实际结果。可附相关截图或最小日志片段，不需要上传完整日志、存档或转储；移除私人路径及账号信息。
- Include the mod version, game build, UE4SS prerequisite version, reproduction steps and expected/actual behavior. Relevant screenshots or minimal log excerpts are welcome; full logs, saves and dumps are not required. Remove private paths and account details.
- 保持战斗数据只读。说明你改了什么、为什么，以及在哪个游戏版本和场景验证。涉及对象生命周期、Map 读取或重载的改动应检查死亡／重进、F3 和 F4。
- Keep combat data read only. Explain the change, reason and tested build/encounter. For lifecycle, map-reading or reload changes, check death/re-entry, F3 and F4.
- 不提交游戏／前置二进制、存档、私人日志、转储、凭据或本机绝对路径。不要把基础权重描述为最终加权贡献。
- Do not submit game/prerequisite binaries, saves, private logs, dumps, credentials or machine-specific paths. Do not label base weights as final weighted contributions.

本项目无需编译。发行包命令见 [CLAUDE.md](CLAUDE.md)；实战验证需要游戏和对应前置。

There is no compilation step. See [CLAUDE.md](CLAUDE.md) for packaging; runtime verification requires the game and its prerequisite.

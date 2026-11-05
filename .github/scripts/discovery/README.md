# 每日公益活动发现

`discover-activities.yml` 每天北京时间 **09:23**（UTC 01:23）运行，也支持手动运行。
GitHub 定时任务仅在默认分支生效，可能延迟；长期无仓库活动时也可能被平台停用。

## 启用

1. 合并本功能 PR 到 `main`。
2. 在仓库 **Settings → Secrets and variables → Actions → Secrets** 配置：
   - `TAVILY_API_KEY`：Tavily Search API 密钥，用于真实联网搜索与正文获取。
   - `OPENAI_API_KEY`：OpenAI API 密钥，用于从检索正文提取结构化活动。
3. 在 **Settings → Actions → General → Workflow permissions** 勾选
   **Allow GitHub Actions to create and approve pull requests**。若组织策略禁止，
   需要组织管理员允许；本工作流不执行批准或合并。
4. 首次在 Actions 中选择 **Daily activity discovery → Run workflow**，
   保持 `dry_run=true`，下载 `discovery-evidence` artifact 并检查来源。
5. 确认结果后，用 `dry_run=false` 手动运行，或等待每日定时执行。

未配置密钥时会明确失败，不会生成模拟活动或修改数据。密钥只通过环境变量提供，
请勿写入配置文件、Issue、PR 正文或日志。

可选 Repository Variables：

| 变量 | 默认值 | 用途 |
| --- | --- | --- |
| `OPENAI_BASE_URL` | `https://api.openai.com/v1` | HTTPS Chat Completions 兼容服务的 API 根地址 |
| `OPENAI_MODEL` | `gpt-4o-mini` | 必须支持 JSON object 输出和 `max_completion_tokens` |
| `DISCOVERY_MAX_SOURCES` | `20` | 每次最多提取的正文数，范围 1–50 |

自定义模型服务会收到搜索返回的公开正文，请先确认服务可信及相关数据政策。

## 检索范围和成本

`queries.json` 定义渠道、关键词及可选域名限制，支持 `{year}`、`{month}`、
`{next_year}` 占位符，按北京时间动态计算。默认包含：

- 微信公众号公开文章：`mp.weixin.qq.com`。
- 志愿服务平台：中国志愿服务网、志愿北京等。
- 公益平台：腾讯公益、公益宝、中国发展简报等。
- 不限域名的公开网页搜索：公益活动、志愿招募、公益会议与竞赛。

默认每次 **7 条 advanced 搜索**，每条最多 5 个结果，检索最近一个月的内容；
最多对 20 篇去重正文调用模型，每篇最多取前 16,000 字符、提取 3 个活动。
正文按渠道轮流选取，避免某个渠道占满提取名额。
使用近期发布范围可能漏掉早期发布但尚在报名的活动，可修改 `time_range`。
Tavily 和模型服务均可能收费，失败重试最多 3 次，请自行设置供应商费用限额。
网络请求超时为 60 秒，工作流总超时 30 分钟。

“全网搜索”指多渠道公开网页检索，不保证穷尽所有网页。微信文章是否能被发现取决于
搜索引擎收录及正文可访问性。不会登录微信、绕过验证码或访问私域群聊；
仅有搜索摘要、正文不可读的文章会跳过并记录在报告中，不根据摘要补全活动。

## 数据质量与审核

流程为：搜索 → 正文提取 → 本地校验 → 去重 → 追加 YAML → 数据 PR。

- 仅接受 `meetup`、`conference`、`competition`，并要求明确公益属性。
- 校验完整日期、时间顺序、IANA 时区及活动是否结束。
- 要求活动名、开始/结束时间、地点、公益属性各有一段可在正文中原样匹配的证据。
- 明确到日期但未写时刻时，允许当天 `00:00:00` / `23:59:59`；日期不明则跳过。
- 活动链接由检索结果提供，ID 由程序生成，不接受模型生成的链接或 ID。
- 按 ID、规范化标题加开始时间、规范化来源链接加开始时间去重。
  微信长链接保留 `__biz`、`mid`、`idx`、`sn`，去掉分享跟踪参数。
- 只追加新记录，不重新格式化历史 YAML。不改餐厅、课程或现有投稿流程。
- 全部搜索失败或全部正文提取失败会使工作流失败；局部失败会记录在证据报告中。
  无结果是正常情况，不会新建空 PR；报告包含检索数量、跳过原因和新增证据。

证据匹配只能证明引文出现在正文中，不能保证模型对日期、地点、主办方的解释正确。
维护者仍需打开原文逐条审核公益属性、活动时间、报名状态和链接真实性，尤其是募捐活动。
不要仅凭模型输出批准活动。来源网页被当作不可信输入，模型没有工具或仓库写权限；
模型输出仅通过受限字段映射写入 YAML，不作为命令执行。

## 待审核 PR 的生命周期

工作流使用固定分支 `automation/daily-activities`，持续更新同一个待审核 PR。
每次从 `main` 开始，读取自动化分支中尚未合并的活动，再合并当天新结果；
因此次日没有搜索到新活动，也不会覆盖已有待审核活动。分支读取失败时直接终止。
待审核记录先与分支共同祖先比较，只保留新增活动，避免将主分支已删除的历史记录带回。

合并前可编辑自动化分支中的活动字段。若拒绝某个活动，应同时调整查询条件以减少再次命中；
当前未实现持久拒绝名单。关闭整个自动化 PR 后，应删除该自动化分支或禁用工作流，
否则后续运行可能重新提交未合并的活动。需要停用时，在 Actions 页面禁用本工作流。

`discovery-evidence` artifact 保存 30 天，包含本次新增活动的原文引文、来源 URL 和渠道。
已有待审核活动的证据应在首次发现该活动的历史运行中查看；当前报告的 `retained`
只表示保留数量。PR 每天更新时会链接最新运行，可通过 Actions 历史定位早期证据。

使用内置 `GITHUB_TOKEN` 创建的数据 PR 不会触发其他 `pull_request` 工作流；
发现任务本身先执行离线测试与生成 YAML 的解析校验，但不能替代人工数据审核。
维护者手动合并后，原有 `Data deployment` 会将数据发布到网站。

## 本地测试

需要 Node.js 24：

```sh
npm ci --prefix .github/scripts/discovery --ignore-scripts
npm test --prefix .github/scripts/discovery
```

测试使用固定检索与模型响应，不需要密钥，也不会联网或修改正式活动数据。

本地真实试运行时，通过环境变量提供两项密钥，并设置 `DISCOVERY_DRY_RUN=true`，
然后从仓库根目录运行：

```sh
node .github/scripts/discovery/discover.mjs
```

默认报告为被 Git 忽略的 `discovery-report.json`。可通过 `DISCOVERY_REPORT`
指定其他路径；`ACTIVITIES_FILE` 和 `PENDING_ACTIVITIES_FILE` 可指定测试数据及待审核数据。
`PENDING_BASE_FILE` 指定待审核分支共同祖先的数据，用于排除历史记录。
本地执行不负责创建 PR，创建 PR 由 GitHub Actions 中的专用步骤完成。

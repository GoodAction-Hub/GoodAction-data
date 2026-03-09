# GoodAction Hub 数据仓库 / GoodAction Hub Data Repository

本仓库是 [GoodAction Hub](https://github.com/GoodAction-Hub/GoodAction-Hub.github.io) 的独立数据仓库，用于存储公益慈善活动、会议和竞赛的结构化数据。

This repository is the standalone data repository for [GoodAction Hub](https://github.com/GoodAction-Hub/GoodAction-Hub.github.io), storing structured data for public welfare activities, conferences, and competitions.

## 功能入口 / Features

- [提交活动 / Submit Activity][1]
- [审核列表 / Review List][2]
- [JSON API][3]

## 如何添加活动数据 / How to Add Activity Data

💡 **新手友好**：推荐通过上方功能入口的"[提交活动][1]"链接来提交，填写表单即可，无需了解 Git 操作。

💡 **Beginner-friendly**: It is recommended to submit via the "[Submit Activity][1]" link above — just fill in a form, no Git knowledge needed.

所有活动数据都存储在 `data/activities.yml` 中，`category` 字段区分类型（`meetup`、`conference`、`competition`）。

All activity data is stored in `data/activities.yml`, with the `category` field distinguishing the type (`meetup`, `conference`, `competition`).

如果您熟悉 Git 和 Pull Request 流程，也可以直接编辑 `data/activities.yml` 并提交 Pull Request。

If you are familiar with Git and Pull Requests, you can also directly edit `data/activities.yml` and submit a Pull Request.

## 数据结构 / Data Structure

请在 `data/activities.yml` 中，仿照以下格式添加新条目：

```yaml
- title: 活动名称 (例如：第三届老龄志愿与公益服务学术论坛)
  description: 探讨AI时代应对人口老龄化的新策略，推动我国老龄志愿与公益服务事业多元发展
  category: conference # meetup | conference | competition
  tags:
    - 老龄服务
    - 志愿公益
    - 人工智能
    - 学术论坛
  events:
    - id: aging-volunteer-forum-2025 # 全局唯一的ID
      link: https://mp.weixin.qq.com/s/qi9gF1ETgk6UvFnnGNSVlg # 链接
      start_time: '2025-11-15 09:00:00' # 开始时间
      end_time: '2025-11-16 17:00:00' # 结束时间
      timezone: Asia/Shanghai # 所在时区
      place: 中国，北京 # 地点
```

**注意事项 / Notes:**

- `category`: 必须是 `meetup`、`conference` 或 `competition`
- `start_time` / `end_time`: 格式为 `YYYY-MM-DD HH:mm:ss`
- `timezone`: 请使用标准的 IANA 时区名称（例如 `Asia/Shanghai`），否则会影响时区转换
- `place`: 活动地址，如 `中国，上海`（`国家，城市`）；如果是线上活动，直接写 `线上`

> 🎉 **每一份贡献都很珍贵，欢迎您的参与！**

## 灵感来源 / Inspiration

- [GoodAction-Hub/GoodAction-Hub.github.io](https://github.com/GoodAction-Hub/GoodAction-Hub.github.io)

[1]: https://github.com/GoodAction-Hub/GoodAction-data/issues/new?template=activity.yml
[2]: https://github.com/GoodAction-Hub/GoodAction-data/pulls
[3]: https://goodaction-hub.github.io/GoodAction-data/

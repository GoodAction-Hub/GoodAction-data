# GoodAction Hub 数据仓库 / GoodAction Hub Data Repository

本仓库是 [GoodAction Hub](https://github.com/GoodAction-Hub/GoodAction-Hub.github.io) 的独立数据仓库，用于存储公益慈善活动、会议和竞赛的结构化数据。

This repository is the standalone data repository for [GoodAction Hub](https://github.com/GoodAction-Hub/GoodAction-Hub.github.io), storing structured data for public welfare activities, conferences, and competitions.

## 功能入口 / Features

- [提交公益活动 / Submit Activity][1]
- [提交公益会议 / Submit Conference][2]
- [提交公益竞赛 / Submit Competition][3]

## 如何添加活动数据 / How to Add Activity Data

我们非常欢迎社区贡献！如果您发现有未收录的公益慈善会议、竞赛及活动，或者信息有误，请通过提交 Issue 或 Pull Request 的方式来帮助我们更新。

We warmly welcome community contributions! If you find unlisted public welfare conferences, competitions, or activities, or if there are any errors, please help us update by submitting an Issue or Pull Request.

所有活动数据都存储在 `/data` 目录下的 YAML 文件中：

- **会议 / Conferences**: 请添加到 `data/conferences.yml`
- **竞赛 / Competitions**: 请添加到 `data/competitions.yml`
- **活动 / Activities**: 请添加到 `data/activities.yml`

## 数据结构 / Data Structure

请在对应的 YAML 文件中，仿照以下格式添加新条目：

```yaml
- title: 活动名称 (例如：第三届老龄志愿与公益服务学术论坛)
  description: 探讨AI时代应对人口老龄化的新策略，推动我国老龄志愿与公益服务事业多元发展
  category: conference # 会议请使用 "conference"，竞赛请使用 "competition"，活动请使用 "activity"
  tags:
    - 老龄服务
    - 志愿公益
    - 人工智能
    - 学术论坛
  events:
    - year: 2025 # 年份
      id: aging-volunteer-forum-2025 # 全局唯一的ID
      link: https://mp.weixin.qq.com/s/qi9gF1ETgk6UvFnnGNSVlg # 链接
      timeline:
        - deadline: '2025-10-19T23:59:00' # 关键日期 (ISO 8601 格式)
          comment: '论文征集截止' # 日期说明
        - deadline: '2025-11-15T09:00:00'
          comment: '学术年会开始'
        - deadline: '2025-11-16T17:00:00'
          comment: '学术年会结束'
      timezone: Asia/Shanghai # 所在时区
      date: 2025年11月15日-11月16日 # 人类可读的日期范围
      place: 中国，北京 # 地点
```

**注意事项 / Notes:**

- `category`: 必须是 `conference`、`competition` 或 `activity`
- `timeline.deadline`: 请使用 ISO 8601 标准格式 - `YYYY-MM-DDTHH:mm:ss`
- `timezone`: 请使用标准的 IANA 时区名称（例如 `Asia/Shanghai`），否则会影响时区转换
- `date`: 请使用人类可读的单个日期或日期范围，如 `2025年4月30日` 或 `2025年4月30日-9月30日`
- `place`: 活动地址，如 `中国，上海`（`国家，城市`）；如果是线上活动，直接写 `线上`

💡 **新手友好提示**：如果您不熟悉 Pull Request 流程，也可以通过 Issues 方式提交活动信息，我们来帮您添加。

> 🎉 **每一份贡献都很珍贵，欢迎您的参与！**

[1]: https://github.com/GoodAction-Hub/GoodAction-data/issues/new?template=activity.yml
[2]: https://github.com/GoodAction-Hub/GoodAction-data/issues/new?template=conference.yml
[3]: https://github.com/GoodAction-Hub/GoodAction-data/issues/new?template=competition.yml

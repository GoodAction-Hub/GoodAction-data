# GoodAction Hub 数据仓库 / GoodAction Hub Data Repository

本仓库是 [GoodAction Hub](https://github.com/GoodAction-Hub/GoodAction-Hub.github.io) 的独立数据仓库，用于存储公益慈善活动、会议和竞赛的结构化数据。

This repository is the standalone data repository for [GoodAction Hub](https://github.com/GoodAction-Hub/GoodAction-Hub.github.io), storing structured data for public welfare activities, conferences, and competitions.

## 功能入口 / Features

- [提交活动 / Submit Activity][1]
- [提交餐厅 / Submit Restaurant][2]
- [审核列表 / Review List][3]
- [JSON API][4]

## 如何添加数据 / How to Add Data

💡 **新手友好**：推荐通过上方功能入口的"[提交活动][1]"或"[提交餐厅][2]"链接来提交，填写表单即可，无需了解 Git 操作。

💡 **Beginner-friendly**: Submit via the "[Submit Activity][1]" or "[Submit Restaurant][2]" links above — just fill in a form, no Git knowledge needed.

- 活动数据存储在 `data/activities.yml`，`category` 字段区分类型（`meetup`、`conference`、`competition`）。
- 餐厅数据存储在 `data/restaurants.yml`。

All activity data is stored in `data/activities.yml`; all restaurant data is stored in `data/restaurants.yml`.

如果您熟悉 Git 和 Pull Request 流程，也可以直接编辑对应文件并提交 Pull Request。

If you are familiar with Git and Pull Requests, you can also directly edit the corresponding file and submit a Pull Request.

## 数据结构 / Data Structure

### 活动 / Activities

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
      timeline:
        - deadline: '2025-10-19T23:59:00' # 关键日期 (ISO 8601 格式)
          comment: '论文征集截止' # 日期说明
        - deadline: '2025-11-15T09:00:00'
          comment: '学术年会开始'
        - deadline: '2025-11-16T17:00:00'
          comment: '学术年会结束'
      timezone: Asia/Shanghai # 所在时区
      place: 中国，北京 # 地点
```

**注意事项 / Notes:**

- `category`: 必须是 `meetup`、`conference` 或 `competition`
- `start_time` / `end_time`: 活动整体的开始和结束时间，格式为 `YYYY-MM-DD HH:mm:ss`
- `timeline.deadline`: 每个环节的关键时间节点，请使用 ISO 8601 标准格式 - `YYYY-MM-DDTHH:mm:ss`
- `timezone`: 请使用标准的 IANA 时区名称（例如 `Asia/Shanghai`），否则会影响时区转换
- `place`: 活动地址，如 `中国，上海`（`国家，城市`）；如果是线上活动，直接写 `线上`

### 餐厅 / Restaurants

请在 `data/restaurants.yml` 中，仿照以下格式添加新条目：

```yaml
- id: aimer-coffee-shanghai # 全局唯一的 ID
  name: 爱默咖啡 # 餐厅名称（即 Issue 标题）
  description: 一家提供手语服务、无障碍通道的温暖咖啡馆
  features:
    - 手语服务
    - 无障碍通道
    - 盲文菜单
  food:
    - name: 招牌咖啡
      price: ¥35
    - name: 无障碍套餐
      price: ¥68
  avg_spend: ¥50
  social_values:
    - 残障就业支持
    - 无障碍通道
  address: 上海市静安区示例路1号
  lat: "31.2304" # GPS 纬度
  lng: "121.4737" # GPS 经度
  issue_link: https://github.com/GoodAction-Hub/GoodAction-data/issues/1
```

> 🎉 **每一份贡献都很珍贵，欢迎您的参与！**

## 灵感来源 / Inspiration

- [BiYuanShe/Fake-Open-Source-wiki](https://github.com/BiYuanShe/Fake-Open-Source-wiki)

[1]: https://github.com/GoodAction-Hub/GoodAction-data/issues/new?template=activity.yml
[2]: https://github.com/GoodAction-Hub/GoodAction-data/issues/new?template=restaurant.yml
[3]: https://github.com/GoodAction-Hub/GoodAction-data/pulls
[4]: https://goodaction-hub.github.io/GoodAction-data/

## 数据接口 / Data Interface

1. [activities](https://goodaction-hub.github.io/GoodAction-data/activities.json)
2. [restaurants](https://goodaction-hub.github.io/GoodAction-data/restaurants.json)

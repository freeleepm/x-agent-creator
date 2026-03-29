---
name: x-agent-creator
description: 创建符合标准化规范的 Agent，支持智能调度和安全红线。适用于：(1) 用户说"创建一个帮我写代码的助手"；(2) 用户需要统一团队 Agent 创建标准；(3) 小白用户想快速创建一个符合规范的 Agent 而不需要了解技术细节。
---

# X Agent Creator

## Overview

一键创建符合标准化规范的 Agent，自动注入铁律、任务目录制度、安全红线、记忆管理和多Agent协作机制。

## 创建流程

### 1. 接收用户需求

用户描述需求，例如：
- "帮我创建一个写代码的助手"
- "创建一个分析数据的 Agent"

### 2. 推断 Agent 类型

根据描述关键词自动推断：

| 关键词 | 判断 | type |
|:--------|:-----|:-----|
| 写代码/开发/执行命令 | 需要执行命令 | `exec` |
| 看/分析/不执行 | 只读操作 | `read-only` |
| 发消息/飞书/群管理 | 需要飞书操作 | `feishu`（v2） |

### 3. 询问确认

```
请确认创建：
- 名称：xxx
- 类型：exec
- 规范：铁律 + 任务目录制度 + 安全红线 + 记忆管理 + 协作机制

确认创建？（yes/no）
```

### 4. 执行创建

```bash
# 1. 系统创建基础结构
openclaw agents add ${AGENT_NAME} --workspace /root/.openclaw/workspace-${AGENT_NAME}

# 2. 创建标准目录
mkdir -p workspace-${AGENT_NAME}/{tasks,deliverables,memory}

# 3. 注入规范模板
# - 铁律 + 检查清单
# - 任务目录制度
# - 安全红线
# - 记忆管理
# - 多Agent协作机制

# 4. 配置类型权限
# - exec: exec + fs + runtime
# - read-only: fs(readonly) + runtime
```

## 规范体系

### 体系1：执行纪律

**铁律**：接到任务第一动作必须是创建任务目录 + plan.md

**检查清单**：
- [ ] 任务目录已创建
- [ ] plan.md 已创建
- [ ] deliverables/ 已准备

**任务目录制度**：
- 命名：`tasks/YYYY-MM-DD__序号__任务名/`
- 结构：plan.md / notes.md / deliverables/ / code/ / docs/ / assets/

### 体系2：安全边界

**红线**：
- 不泄露私人数据
- 删除/权限/配置修改前必须确认
- 不确认不执行破坏性操作
- 优先用 trash

**操作权限**：
- 自由做：读取、搜索、在工作区内工作
- 需询问：发送邮件、公开发布、离开机器的操作
- 例外：已获长期授权的操作可直接执行

### 体系3：协作机制

**记忆管理**：
- MEMORY.md：只在主会话读取
- 每日记录：memory/YYYY-MM-DD.md
- 维护：定期整理到 MEMORY.md

**多Agent协作**：
- 执行者创建：谁执行谁在 workspace 创建任务目录
- 文件传递：从 deliverables/ 直接发送
- 工作区边界：每个 Agent 管自己的目录

## 智能调度

### 调度决策树

```
任务进来
    │
    ▼
用户指定了 Agent？ ──► 直接 spawn（用户意图优先）
    │
    否
    ▼
主Agent快速判断：简单任务？
    │
    │（一句话能回答/不需要权限）
    ├─► 是 → 主Agent直接处理
    │
    └─► 否（耗时较长）
         ▼
    需要权限（exec/fs）？
         │
         ├─► 是 → 有对应Agent？──► spawn
         │               │
         │               └─► 没有 → 自动创建临时Agent（用完关闭）
         │
         └─► 否 → 主Agent直接处理
```

### 简单任务判断标准

| 简单（主Agent直接） | 复杂/耗时较长（spawn子Agent） |
|:---------------------|:-------------------------------|
| 一句话能回答 | 需要多步骤 |
| 不需要执行命令 | 需要执行命令/写代码 |
| 不需要查文件 | 需要读/写多个文件 |
| 不需要搜索/分析 | 需要搜索/分析 |

### 临时Agent自动创建规则

当没有对应Agent但任务耗时较长时：
- 自动创建临时Agent处理任务
- 任务完成后临时Agent自动关闭
- 产出物遵循"执行者创建原则"放在deliverables/

## Resources

### scripts/

**create.sh** - 核心创建脚本
- 接收 name + description 参数
- 自动推断 type
- 生成规范模板
- 创建标准目录结构
- 执行 openclaw agents add

### templates/

**base/AGENTS.md** - 通用规范模板
- 铁律 + 检查清单
- 任务目录制度
- 安全红线
- 记忆管理
- 多Agent协作机制
- 会话行为规范

**type/exec.md** - exec 类型配置
- exec 权限：security=full
- 工具：exec + fs + runtime

**type/read-only.md** - read-only 类型配置
- 只读权限：fs(readonly) + runtime
- 无 exec 权限

#!/bin/bash
# x-agent-creator 核心创建脚本 v1.1.0
# 用法：./create.sh <AGENT_NAME> <DESCRIPTION>

set -e

AGENT_NAME="${1:-}"
DESCRIPTION="${2:-}"

if [ -z "$AGENT_NAME" ]; then
    echo "错误：缺少参数"
    echo "用法：./create.sh <AGENT_NAME> [DESCRIPTION]"
    exit 1
fi

# 自动推断 type
infer_type() {
    local desc="$1"
    if echo "$desc" | grep -qiE "写代码|开发|执行|命令|编程|code|script|build"; then
        echo "exec"
    elif echo "$desc" | grep -qiE "看|分析|只读|read|analyze|view"; then
        echo "read-only"
    else
        echo "read-only"  # 默认 read-only
    fi
}

AGENT_TYPE=$(infer_type "$DESCRIPTION")
WORKSPACE_PATH="/root/.openclaw/workspace-${AGENT_NAME}"

echo "============================================"
echo "  x-agent-creator v1.1.0 创建中..."
echo "============================================"
echo "名称：$AGENT_NAME"
echo "类型：$AGENT_TYPE"
echo "描述：$DESCRIPTION"
echo "============================================"

# 1. 创建基础结构
echo "[1/5] 创建基础结构..."
openclaw agents add "$AGENT_NAME" --workspace "$WORKSPACE_PATH" 2>/dev/null || {
    echo "警告：openclaw agents add 失败，尝试手动创建目录..."
    mkdir -p "$WORKSPACE_PATH"
}

# 2. 创建标准目录
echo "[2/5] 创建标准目录..."
mkdir -p "$WORKSPACE_PATH"/{tasks/deliverables,memory,archives,temp}

# 3. 生成 AGENTS.md 规范模板
echo "[3/5] 注入规范模板..."
cat > "$WORKSPACE_PATH/AGENTS.md" << 'AGENTS_EOF'
# AGENTS.md - 标准化 Agent 规范 v1.1.0

## 🚨 铁律（任何任务都不能跳过）

> ⚠️ **【铁律】接到任何任务后的第一个动作必须是：创建任务目录 + plan.md**
> - 不管任务多简单、多紧急
> - 不管是用户直接说还是通过对话接受
> - **未创建任务目录和 plan.md 之前，禁止开始任何实质性工作**
> - 违反此规则等同于违规，会被用户和自身监督机制纠正

> **📝 自我检查清单（每次开始任务前必须确认）：**
> - [ ] 任务目录 `tasks/YYYY-MM-DD__序号__任务名/` 已创建
> - [ ] `plan.md` 已创建并记录任务目标
> - [ ] 待交付文件将放在 `deliverables/` 目录

---

## 🚀 核心原则

### 每次会话开始时
1. 阅读 `SOUL.md` —— 这定义了你是谁
2. 阅读 `USER.md` —— 这是谁在使用你
3. 阅读 `memory/YYYY-MM-DD.md`（今天和昨天）

### 任务目录制度

**执行顺序（强制）：**
> 1. 任务接收后，**第一个动作**是创建任务目录 `tasks/YYYY-MM-DD__序号__任务名/`
> 2. 在该目录下创建 `plan.md`，记录任务目标和要求
> 3. 完成上述两步后，才能开始执行实质性工作
> 4. **禁止在目录和 plan.md 创建之前开始任何实质性工作**

**目录命名**：`tasks/YYYY-MM-DD__序号__任务名/`
**标准结构**：
- plan.md — 任务计划
- notes.md — 过程记录
- deliverables/ — 最终交付物
- code/ — 代码文件
- docs/ — 文档文件
- assets/ — 资源文件

---

## ⚠️ 安全红线

- ❌ 不泄露私人数据
- ❌ 不在未确认前执行破坏性操作
- ❌ 不修改/删除他人文件
- ❌ 不确认不执行删除、权限修改操作
- ✅ 优先用 `trash`，不用 `rm`

---

## 🧠 记忆管理

- **每日记录**：`memory/YYYY-MM-DD.md` —— 原始日志
- **长期记忆**：`MEMORY.md` —— 只在主会话读取
- **原则**："文字比脑内记忆更可靠"

---

## 🤝 多Agent协作

- **执行者创建**：谁执行任务，谁在 workspace 创建任务目录
- **文件传递**：产出放 `deliverables/`，主 Agent 直接发送
- **工作区边界**：每个 Agent 管自己的目录，不跨区操作

---

## 🎯 智能调度决策 v1.1.0

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

---

## 💬 会话行为

- 被直接提问/被要求时才回应
- 群聊中质量 > 数量
- 简单问题主Agent直接处理，复杂任务 spawn 子Agent
- 用户意图优先，不二次确认打断节奏

AGENTS_EOF

# 4. 配置类型权限
echo "[4/5] 配置类型权限..."
if [ "$AGENT_TYPE" = "exec" ]; then
    cat > "$WORKSPACE_PATH/.agent_type" << 'TYPE_EOF'
exec
TYPE_EOF
    echo "类型：exec（可执行命令）"
else
    cat > "$WORKSPACE_PATH/.agent_type" << 'TYPE_EOF'
read-only
TYPE_EOF
    echo "类型：read-only（只读）"
fi

# 5. 创建标准文件
echo "[5/5] 创建标准文件..."
touch "$WORKSPACE_PATH/memory/$(date +%Y-%m-%d).md"

echo ""
echo "============================================"
echo "  ✅ 创建完成！"
echo "============================================"
echo ""
echo "Agent 名称：$AGENT_NAME"
echo "Agent 类型：$AGENT_TYPE"
echo "工作区路径：$WORKSPACE_PATH"
echo "规范版本：v1.1.0"
echo ""
echo "下一步："
echo "1. 修改 SOUL.md 定义 Agent 人格"
echo "2. 修改 USER.md 填入用户信息"
echo "3. 修改 IDENTITY.md 填入对外身份"
echo ""

# Blender MCP × VS Code 部署指南

> **用 VS Code + Copilot Chat 通过 AI 直接控制 Blender 进行 3D 建模！**

本项目是基于 [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)（MIT License）的**二次整理与部署指南**，重点面向 **VS Code** 用户（而非 Claude Desktop），让vscode使用者快速配置并使用 AI 操控 Blender。

---

## 致谢与声明

- **原项目**：[BlenderMCP](https://github.com/ahujasid/blender-mcp) by **Siddharth Ahuja** ([@ahujasid](https://github.com/ahujasid))
- **原项目协议**：MIT License — Copyright (c) 2025 Siddharth Ahuja
- 本仓库**不包含**原项目核心代码的修改版，仅提供面向 VS Code 的配置文件、一键安装脚本和使用教程
- 感谢原作者的开源精神！如果觉得好用，请去 [原项目](https://github.com/ahujasid/blender-mcp) ⭐ Star 支持

---

## 它能做什么？

通过 MCP（Model Context Protocol），你可以在 VS Code 的 Copilot Chat 中用自然语言控制 Blender：

- 🏔 "帮我创建一座雪山场景"
- 🎨 "把这个物体改成红色金属材质"
- 📷 "把相机对准场景并渲染"
- 🌲 "在场景中添加100棵松树"
- 💡 "设置一个日落氛围的灯光"

---

## 前提条件

| 软件 | 版本要求 | 下载地址 |
|------|---------|---------|
| **Blender** | 3.0+ (推荐 4.0+) | [blender.org](https://www.blender.org/download/) |
| **VS Code** | 最新版 | [code.visualstudio.com](https://code.visualstudio.com/) |
| **GitHub Copilot** | VS Code 扩展 | VS Code 扩展商店搜索 "GitHub Copilot" |

---

## 快速安装（3 步搞定）

### 第 1 步：运行一键安装脚本

以**管理员身份**打开 PowerShell，运行：

```powershell
# 进入本项目文件夹（假设你把项目放在桌面）
cd ~/Desktop/blender-mcp-vscode-setup

# 运行安装脚本
.\setup.ps1
```

这个脚本会自动帮你：
- ✅ 安装 `uv` 包管理器（Python 工具链）
- ✅ 配置环境变量（PATH）
- ✅ 测试 `uvx blender-mcp` 能否正常运行
- ✅ 配置 VS Code 的 MCP 服务器

> **如果你不想运行脚本，也可以手动安装，见下面的"手动安装"章节。**

### 第 2 步：在 Blender 中安装插件

1. 打开 Blender
2. 进入菜单 **Edit → Preferences → Add-ons**
3. 点击右上角 **Install...** 按钮
4. 选择本项目中的 `addon.py` 文件
5. 勾选 **"Interface: Blender MCP"** 启用插件

![安装插件](assets/addon-install-hint.png)
*（如果没有图片，按上面文字操作即可）*

### 第 3 步：在 Blender 中连接

1. 在 Blender 3D 视图中，按 **N** 键打开侧边栏
2. 找到 **"BlenderMCP"** 标签页
3. 点击 **"Connect to Claude"** 按钮
4. 看到 **"Running on port 9876"** 就表示连接成功了！

---

## 开始使用

1. 确保 Blender 中插件已连接（显示 "Running on port 9876"）
2. 打开 VS Code
3. 打开 **Copilot Chat**（快捷键 `Ctrl+Alt+I`）
4. 切换到 **Agent 模式**（Chat 窗口顶部下拉选择）
5. 你应该能看到 MCP 工具列表中有 Blender 相关的工具
6. 直接用自然语言对话，比如：

```
帮我在 Blender 中创建一个简单的桌子，木质材质
```

AI 就会自动调用 Blender MCP 来创建 3D 场景！

---

## 手动安装（不用脚本）

如果你更喜欢手动操作，按以下步骤来：

### 1. 安装 uv 包管理器

打开 PowerShell 运行：

```powershell
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

然后添加到 PATH（**重启终端后生效**）：

```powershell
$localBin = "$env:USERPROFILE\.local\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$localBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$localBin", "User")
}
```

### 2. 测试安装

```powershell
# 重启终端后运行
uvx blender-mcp
```

看到类似下面的输出就是成功了（按 Ctrl+C 退出）：

```
Could not connect to Blender addon. Make sure Blender is running...
```

这是因为 Blender 还没启动，属于正常现象。

### 3. 配置 VS Code MCP

将 `mcp-config/mcp.json` 的内容复制到：

```
%APPDATA%\Code\User\mcp.json
```

或者手动创建该文件，内容为：

```json
{
    "servers": {
        "blender": {
            "type": "stdio",
            "command": "cmd",
            "args": ["/c", "uvx", "blender-mcp"]
        }
    }
}
```

> **注意**：Windows 下必须用 `cmd /c uvx blender-mcp` 的形式，不能直接用 `uvx`。

### 4. 安装 Blender 插件

见上面"第 2 步"。

---

## 文件结构说明

```
blender-mcp-vscode-setup/
├── README.md              ← 你正在看的这个文件
├── LICENSE                ← MIT 许可证（遵循原项目）
├── setup.ps1              ← Windows 一键安装脚本
├── addon.py               ← Blender 插件（来自原项目）
├── mcp-config/
│   └── mcp.json           ← VS Code MCP 配置模板
└── examples/
    └── demo_scene.py      ← 示例：用 Python 创建场景
```

---

## 常见问题

### Q: 连接不上怎么办？

1. 确认 Blender 已打开，且插件显示 "Running on port 9876"
2. 确认 VS Code 已重启（修改 mcp.json 后需要重启）
3. 检查防火墙是否阻止了 localhost:9876 的连接

### Q: VS Code Copilot Chat 中看不到 Blender 工具？

1. 确认已切换到 **Agent 模式**（不是普通 Chat 模式）
2. 确认 `mcp.json` 配置正确放在 `%APPDATA%\Code\User\` 目录下
3. 重启 VS Code


### Q: 和原版 blender-mcp 有什么区别？

原版主要面向 Claude Desktop 和 Cursor 用户，本项目专门为 **VS Code + Copilot** 用户提供了：
- Windows 一键安装脚本
- VS Code 专属 MCP 配置
- 中文教程

### Q: 支持 Mac / Linux 吗？

uv 和 blender-mcp 本身支持跨平台，但本项目的安装脚本目前只适配了 Windows。Mac/Linux 用户可以参考[原项目文档](https://github.com/ahujasid/blender-mcp)手动安装。

---

## 工作原理简介

```
┌─────────────┐    MCP协议     ┌──────────────┐   TCP Socket   ┌─────────┐
│  VS Code    │ ◄────────────► │  MCP Server  │ ◄────────────► │ Blender │
│  Copilot    │   (stdio)      │  (uvx运行)    │  (port 9876)  │  Addon  │
└─────────────┘                └──────────────┘                └─────────┘
```

1. **VS Code Copilot** 通过 MCP 协议调用 MCP Server
2. **MCP Server**（由 `uvx blender-mcp` 启动）将指令转换为 TCP 命令
3. **Blender Addon**（addon.py）在 Blender 内监听 9876 端口，接收并执行 Python 代码

---

## 相关链接

- 原项目：[github.com/ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
- 原项目教程视频：[YouTube](https://www.youtube.com/watch?v=lCyQ717DuzQ)
- uv 包管理器：[astral.sh/uv](https://docs.astral.sh/uv/)
- MCP 协议：[modelcontextprotocol.io](https://modelcontextprotocol.io/)

---

*本项目基于 [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp) 二次整理，遵循 MIT License。*

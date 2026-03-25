<#
.SYNOPSIS
    Blender MCP + VS Code 一键安装脚本
.DESCRIPTION
    自动安装 uv 包管理器，配置 VS Code MCP 服务器，
    让你通过 VS Code Copilot Chat 控制 Blender。
    基于 ahujasid/blender-mcp (MIT License)
.NOTES
    请以管理员权限运行，或确保有写入用户目录的权限。
#>

param(
    [switch]$SkipUv,
    [switch]$SkipMcpConfig
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Blender MCP x VS Code 安装脚本" -ForegroundColor Cyan
Write-Host "  原项目: github.com/ahujasid/blender-mcp" -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ─── Step 1: 检查并安装 uv ───

if (-not $SkipUv) {
    Write-Host "[1/4] 检查 uv 包管理器..." -ForegroundColor Yellow

    $uvPath = "$env:USERPROFILE\.local\bin\uv.exe"
    $uvInPath = Get-Command uv -ErrorAction SilentlyContinue

    if ($uvInPath) {
        Write-Host "  ✓ uv 已安装: $($uvInPath.Source)" -ForegroundColor Green
    } elseif (Test-Path $uvPath) {
        Write-Host "  ✓ uv 已安装在 $uvPath（但未在 PATH 中）" -ForegroundColor Green
    } else {
        Write-Host "  → 正在安装 uv..." -ForegroundColor White
        try {
            Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
            Write-Host "  ✓ uv 安装完成" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ uv 安装失败: $_" -ForegroundColor Red
            Write-Host "  请手动访问 https://docs.astral.sh/uv/getting-started/installation/" -ForegroundColor Red
            exit 1
        }
    }

    # 确保 uv 在 PATH 中
    $localBin = "$env:USERPROFILE\.local\bin"
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$localBin*") {
        Write-Host "  → 将 uv 添加到用户 PATH..." -ForegroundColor White
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$localBin", "User")
        $env:Path = "$env:Path;$localBin"
        Write-Host "  ✓ PATH 已更新" -ForegroundColor Green
    }
} else {
    Write-Host "[1/4] 跳过 uv 安装 (--SkipUv)" -ForegroundColor DarkGray
}

# ─── Step 2: 测试 uvx blender-mcp ───

Write-Host ""
Write-Host "[2/4] 测试 blender-mcp 可用性..." -ForegroundColor Yellow

# 确保当前 session 能找到 uvx
$localBin = "$env:USERPROFILE\.local\bin"
if ($env:Path -notlike "*$localBin*") {
    $env:Path = "$env:Path;$localBin"
}

$uvxCmd = Get-Command uvx -ErrorAction SilentlyContinue
if (-not $uvxCmd) {
    Write-Host "  ✗ 找不到 uvx 命令，请重新打开终端后再试" -ForegroundColor Red
    Write-Host "  或手动运行: powershell -c `"irm https://astral.sh/uv/install.ps1 | iex`"" -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ uvx 可用: $($uvxCmd.Source)" -ForegroundColor Green
Write-Host "  （blender-mcp 会在首次使用时自动下载依赖）" -ForegroundColor DarkGray

# ─── Step 3: 配置 VS Code MCP ───

if (-not $SkipMcpConfig) {
    Write-Host ""
    Write-Host "[3/4] 配置 VS Code MCP 服务器..." -ForegroundColor Yellow

    $mcpConfigDir = "$env:APPDATA\Code\User"
    $mcpConfigPath = "$mcpConfigDir\mcp.json"

    $mcpContent = @'
{
    "servers": {
        "blender": {
            "type": "stdio",
            "command": "cmd",
            "args": ["/c", "uvx", "blender-mcp"]
        }
    }
}
'@

    if (Test-Path $mcpConfigPath) {
        Write-Host "  ! mcp.json 已存在: $mcpConfigPath" -ForegroundColor DarkYellow
        Write-Host "  现有内容:" -ForegroundColor DarkGray
        Get-Content $mcpConfigPath | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

        $confirm = Read-Host "  是否覆盖？(y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "  → 跳过 MCP 配置" -ForegroundColor DarkGray
        } else {
            Set-Content -Path $mcpConfigPath -Value $mcpContent -Encoding UTF8
            Write-Host "  ✓ mcp.json 已更新" -ForegroundColor Green
        }
    } else {
        if (-not (Test-Path $mcpConfigDir)) {
            New-Item -ItemType Directory -Path $mcpConfigDir -Force | Out-Null
        }
        Set-Content -Path $mcpConfigPath -Value $mcpContent -Encoding UTF8
        Write-Host "  ✓ mcp.json 已创建: $mcpConfigPath" -ForegroundColor Green
    }
} else {
    Write-Host ""
    Write-Host "[3/4] 跳过 MCP 配置 (--SkipMcpConfig)" -ForegroundColor DarkGray
}

# ─── Step 4: 提示安装 Blender 插件 ───

Write-Host ""
Write-Host "[4/4] Blender 插件安装提示" -ForegroundColor Yellow
Write-Host ""

$addonPath = Join-Path $PSScriptRoot "addon.py"
if (Test-Path $addonPath) {
    Write-Host "  插件文件位于: $addonPath" -ForegroundColor White
} else {
    Write-Host "  ! addon.py 未找到，请从原项目下载:" -ForegroundColor DarkYellow
    Write-Host "  https://github.com/ahujasid/blender-mcp/blob/main/addon.py" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  请手动完成以下步骤：" -ForegroundColor White
Write-Host "  1. 打开 Blender" -ForegroundColor White
Write-Host "  2. Edit → Preferences → Add-ons" -ForegroundColor White
Write-Host "  3. 点击 Install... 选择 addon.py" -ForegroundColor White
Write-Host "  4. 勾选 'Interface: Blender MCP' 启用" -ForegroundColor White
Write-Host "  5. 按 N 打开侧边栏 → BlenderMCP → Connect to Claude" -ForegroundColor White

# ─── 完成 ───

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  接下来：" -ForegroundColor White
Write-Host "  1. 在 Blender 中连接插件（侧边栏 → BlenderMCP → Connect）" -ForegroundColor White
Write-Host "  2. 重启 VS Code" -ForegroundColor White
Write-Host "  3. 打开 Copilot Chat (Ctrl+Alt+I) → 切换到 Agent 模式" -ForegroundColor White
Write-Host "  4. 开始对话，例如：'在 Blender 中创建一个雪山场景'" -ForegroundColor White
Write-Host ""
Write-Host "  遇到问题？查看 README.md 的常见问题章节" -ForegroundColor DarkGray
Write-Host ""

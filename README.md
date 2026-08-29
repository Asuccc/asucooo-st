# Termux 一键安装 SillyTavern

在安卓手机 / 平板的 **Termux** 中一键安装并管理 [SillyTavern](https://github.com/SillyTavern/SillyTavern)（AI 聊天前端），提供中文交互式管理菜单，支持启动、更新、卸载，全程无需敲复杂命令。

> 本项目与 SillyTavern 官方无关联，仅提供 Termux 环境的自动化安装与管理脚本。

## ✨ 功能特性

- **一键安装**：自动更新软件源、安装依赖、克隆官方仓库、npm 安装依赖
- **自动自启动**：安装完成后默认开启，重启 Termux 自动弹出管理菜单
- **交互式菜单**：启动 / 更新 / 卸载 / 查看状态，中文提示
- **架构检测**：仅适配 `aarch64` 设备，其他架构友好提示并退出
- **国内镜像可选**：安装时按需切换 npm 国内镜像源（npmmirror），解决下载慢的问题
- **安全默认**：默认仅本机 `localhost` 访问，不暴露到局域网
- **支持管道安装**：`curl | bash` 也能用（自动采用默认选项安装）

## 📱 环境要求

| 项目 | 要求 |
|---|---|
| 系统 | Android 8.0 及以上 |
| 终端 | Termux（请使用 [F-Droid](https://f-droid.org/packages/com.termux/) 或 [GitHub](https://github.com/termux/termux-app/releases) 版本，Play 商店版已无法使用） |
| 架构 | aarch64 (arm64)，Termux 中运行 `uname -m` 可查看 |
| 存储 | 建议预留 2GB 以上空间 |

> 💡 首次使用 Termux 建议先执行 `pkg update -y && pkg upgrade -y`；如需读写手机共享存储（可选），运行 `termux-setup-storage` 并授予权限。

## 🚀 一键安装

**方法一（推荐）：jsDelivr CDN —— 国内用户首选，无需安装 git**

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Asuccc/asucooo-st@main/st.sh -o ~/st.sh && bash ~/st.sh
```

**方法二：GitHub 官方 raw —— 国外网络直连更快**

```bash
curl -fsSL https://raw.githubusercontent.com/Asuccc/asucooo-st/main/st.sh -o ~/st.sh && bash ~/st.sh
```

> 方法一和方法二下载的是**同一个文件**，只是网络路径不同：jsDelivr 在国内有 CDN 节点（不用梯子，国内稳定）；raw 是 GitHub 官方域名（国外快，国内时通时不通）。哪个能通就用哪个。

**方法三：git 方式 —— 自动安装 git，始终获取最新版**

```bash
pkg install -y git && rm -rf ~/.st-tools-sync && git clone --depth 1 https://github.com/Asuccc/asucooo-st.git ~/.st-tools-sync && cp ~/.st-tools-sync/st.sh ~/st.sh && bash ~/st.sh
```

**脚本检测到尚未安装 SillyTavern 时，会自动进入一键安装**（更新软件源 → 装依赖 → 克隆酒馆 → 装依赖 → 开启自启动），全程无需手动选择；安装完成后自动打开管理面板。已安装过的情况下直接打开管理面板：

```bash
bash ~/st.sh
```

安装完成后，用手机浏览器访问 **http://127.0.0.1:8000** 即可进入 SillyTavern 界面。

## 📖 日常使用

```bash
bash ~/st.sh
```

在菜单中即可完成启动、更新、卸载等操作。

| 命令 | 说明 |
|---|---|
| `bash ~/st.sh` | 打开管理菜单 |
| `bash ~/st.sh start` | 直接启动 |
| `bash ~/st.sh update` | 更新到最新版 |
| `bash ~/st.sh uninstall` | 卸载（删除全部数据） |
| `bash ~/st.sh status` | 查看状态信息 |
| `bash ~/st.sh autostart` | 设置打开 Termux 自启动 |
| `bash ~/st.sh switch` | 切换酒馆版本（如 `switch 1.10.2`） |

## 🔄 Termux 自启动

**安装完成后无需重启**：脚本会自动打开一次管理菜单，当场即可使用；之后每次打开 Termux 也会自动弹出管理菜单（默认已开启，无需手动设置）。

如需切换模式或关闭，打开管理菜单选择「**5) 设置 Termux 自启动**」：

1. 运行 `bash ~/st.sh` 打开管理菜单，选择「5) 设置 Termux 自启动」
2. 选择模式：
   - **1) 管理菜单模式**：打开 Termux 自动显示管理菜单（默认，推荐）
   - **2) 直接启动模式**：打开 Termux 直接启动 SillyTavern 服务
   - **3) 关闭**：取消自启动

也可以用命令直接设置：

```bash
bash ~/st.sh autostart on       # 开启（管理菜单模式）
bash ~/st.sh autostart direct   # 开启（直接启动模式）
bash ~/st.sh autostart off      # 关闭
bash ~/st.sh autostart status   # 查看当前状态
```

> 原理：脚本会向 `~/.bashrc` 写入一段带标记的配置块（`# >>> ST-AUTOSTART-BEGIN >>>`），由脚本统一管理，重复设置不会产生冗余。
>
> 临时跳过自启动：在 Termux 里先执行 `export ST_SKIP_AUTOSTART=1` 再打开新会话即可。

## 🔄 切换酒馆版本

在管理面板选择「**6) 切换酒馆版本**」，可查看并切换到 SillyTavern 任意历史版本：

- 输入列表编号，或直接输入完整版本号（如 `1.10.2`）
- 输入 `0` 或默认分支名（如 `release`）可切回跟随最新版
- **切换完成后自动重新安装依赖**（npm install），无需手动操作
- 固定版本模式下直接运行「更新」会自动切回默认分支再更新，无需手动操作

也可以用命令直接切换：

```bash
bash ~/st.sh switch          # 交互式选择版本
bash ~/st.sh switch 1.10.2   # 直接切换到指定版本
```

## 🔌 配置模型后端

SillyTavern 是一个前端界面，**需要连接模型后端才能对话**：

- **远程 API**：在界面右上角「设置」中填入 OpenAI 兼容 API / Claude / Gemini 等服务的 Key 与地址（也可使用各类中转 / 代理服务）
- **本地模型**：可在 Termux 或局域网内其他设备运行 KoboldCpp / llama.cpp 等推理服务，然后在设置中选择对应 API 类型并填写地址
- 详细配置请参考 [SillyTavern 官方文档](https://docs.sillytavern.app/)

## ❓ 常见问题

**Q: 安装/更新时提示「管理脚本同步失败」？**

A: 管理脚本自更新优先走 `github.com` 的 git，失败一般是网络波动，稍后重试 `bash ~/st.sh update` 即可；也可以重新执行「方法一」的 git 安装命令强制拉取最新版。

**Q: npm install 很慢或失败？**

A: 安装时选择切换国内镜像，或手动执行 `npm config set registry https://registry.npmmirror.com` 后重新运行安装。

**Q: 提示「未检测到 pkg 命令」？**

A: 请确认使用的是 Termux 终端（而不是 proot 里的 Debian 等其他环境）。

**Q: 提示架构不支持？**

A: 本脚本仅适配 `aarch64`，运行 `uname -m` 查看你的设备架构。

**Q: 如何在电脑浏览器上访问手机里的 SillyTavern？**

A: 手机和电脑连接同一 WiFi，编辑 `~/SillyTavern/default/config.yaml`：

```yaml
listen: true        # 开启局域网监听
whitelistMode: true # 建议开启白名单模式
```

然后在设置中设置用户名密码，重启后通过 `http://手机局域网IP:8000` 访问。

**Q: 如何修改端口？**

A: 编辑 `~/SillyTavern/default/config.yaml` 中的 `port` 字段，然后重启。

**Q: 聊天记录存在哪里？**

A: 存放在 `~/SillyTavern/data/` 目录下，卸载前请自行备份。

## ⚠️ 免责声明

本脚本仅用于技术学习与合法用途。使用 SillyTavern 及所连接的任何模型服务时，请遵守相关服务条款与当地法律法规。

## 📄 许可证

[MIT](LICENSE)

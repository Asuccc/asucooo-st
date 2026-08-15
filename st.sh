#!/usr/bin/env bash
# ============================================================
#  Termux 一键安装 / 管理 SillyTavern
#
#  用法:
#    bash st.sh              # 交互式管理菜单（默认）
#    bash st.sh install      # 一键安装
#    bash st.sh start        # 启动 SillyTavern
#    bash st.sh update       # 更新到最新版
#    bash st.sh uninstall    # 卸载（删除全部数据）
#    bash st.sh status       # 查看状态信息
#    bash st.sh autostart    # 设置打开 Termux 自启动
#
#  仓库: https://github.com/<你的GitHub用户名>/asucooo-st
# ============================================================

# ================== 发布前请修改 ==================
GITHUB_USER="Asuccc"   # 改成你的 GitHub 用户名
REPO_NAME="asucooo-st"
# =================================================

# ---------- 常量 ----------
ST_DIR="$HOME/SillyTavern"                          # SillyTavern 安装目录
ST_REPO="https://github.com/SillyTavern/SillyTavern.git"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main"
PORT=8000

# 自启动管理（写入 ~/.bashrc 的标记，用于定位和删除配置块）
AUTOSTART_BEGIN="# >>> ST-AUTOSTART-BEGIN >>>"
AUTOSTART_END="# <<< ST-AUTOSTART-END <<<"

# ---------- 颜色与提示 ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[信息]${NC} $*"; }
warn()  { echo -e "${YELLOW}[提示]${NC} $*"; }
error() { echo -e "${RED}[错误]${NC} $*"; }

# ---------- 环境检测 ----------
# 通过管道执行（curl xxx | bash）时 stdin 不是终端，交互提示会失效，
# 此时自动进入非交互模式，全部使用默认选项。
if [ ! -t 0 ]; then
  NONINTERACTIVE=1
  warn "检测到通过管道执行（curl | bash），将使用默认选项自动安装。"
  warn "如需交互式安装，推荐先下载再运行:"
  warn "  curl -fsSL ${BASE_URL}/st.sh -o ~/st.sh && bash ~/st.sh"
  echo
fi

# 确认函数：非交互模式下默认回答 No
confirm() {
  if [ "${NONINTERACTIVE:-0}" = "1" ]; then
    return 1
  fi
  local ans
  read -r -p "$1 [y/N]: " ans
  case "$ans" in
    y|Y) return 0 ;;
    *)   return 1 ;;
  esac
}

is_installed() {
  [ -d "$ST_DIR" ] && [ -f "$ST_DIR/server.js" ]
}

check_env() {
  command -v pkg >/dev/null 2>&1 || {
    error "未检测到 pkg 命令，请确认你正在 Termux 中运行本脚本。"
    exit 1
  }
  local arch
  arch=$(uname -m)
  if [ "$arch" != "aarch64" ]; then
    error "当前架构: $arch，本脚本仅适配 aarch64 (arm64) 设备。"
    exit 1
  fi
}

# ---------- 一键安装 ----------
cmd_install() {
  echo "=============================================="
  echo "      Termux 一键安装 SillyTavern"
  echo "=============================================="
  check_env

  info "更新软件源..."
  pkg update -y || { error "pkg update 失败，请检查网络连接。"; exit 1; }

  if confirm "是否升级全部系统包？(首次使用建议执行，耗时较长)"; then
    pkg upgrade -y || { error "pkg upgrade 失败。"; exit 1; }
  else
    warn "跳过系统包升级。"
  fi

  info "安装依赖 (nodejs-lts, git)..."
  pkg install -y nodejs-lts git || { error "依赖安装失败。"; exit 1; }

  # Node.js 版本检查（SillyTavern 需要 18 及以上）
  NODE_VER=$(node --version 2>/dev/null | sed 's/v//')
  if [ -z "$NODE_VER" ]; then
    error "Node.js 安装失败。"
    exit 1
  fi
  NODE_MAJOR=${NODE_VER%%.*}
  if [ "${NODE_MAJOR:-0}" -lt 18 ]; then
    error "Node.js 版本过低 (v${NODE_VER})，SillyTavern 需要 Node.js 18 及以上。"
    exit 1
  fi
  info "Node.js 版本: v${NODE_VER} ✓"

  if confirm "npm 官方源下载慢？可切换国内镜像源 (npmmirror)"; then
    npm config set registry https://registry.npmmirror.com && info "npm 源已切换为 npmmirror。"
  fi

  if is_installed; then
    warn "检测到 $ST_DIR 已存在，跳过克隆。"
  else
    info "克隆 SillyTavern 官方仓库（main 稳定分支，浅克隆以节省空间）..."
    git clone --depth 1 "$ST_REPO" "$ST_DIR" || { error "克隆失败，请检查网络。"; exit 1; }
  fi

  info "安装依赖 (npm install)，视网络情况可能需要几分钟..."
  (cd "$ST_DIR" && npm install --no-audit --no-fund) || { error "npm install 失败。"; exit 1; }

  # 保存管理脚本本体（管道模式运行时无法自复制，直接下载自身）
  if [ ! -f "$HOME/st.sh" ] && [ "$GITHUB_USER" != "你的GitHub用户名" ]; then
    curl -fsSL "$BASE_URL/st.sh" -o "$HOME/st.sh" 2>/dev/null && chmod +x "$HOME/st.sh" && info "管理脚本已保存到 ~/st.sh"
  fi

  # 自动开启 Termux 自启动（管理菜单模式）：搭建完成后重启 Termux 即自动弹出管理菜单
  autostart_write menu
  info "已自动开启 Termux 自启动（管理菜单模式），重启 Termux 后自动弹出管理菜单。"

  echo
  info "=============================================="
  info "安装完成！"
  info "  启动方式:  bash ~/st.sh            (管理菜单)"
  info "  访问地址:  http://127.0.0.1:${PORT}"
  info "  首次使用:  浏览器打开上述地址，在右上角设置中配置模型 API"
  info "             (OpenAI 兼容接口 / Claude / Gemini / 本地后端等)"
  info "  自启动:    已开启，重启 Termux 后自动弹出管理菜单"
  info "  如需关闭:  bash ~/st.sh autostart off"
  info "  安全提醒:  请及时在设置中设置用户名和密码，防止被他人访问"
  info "=============================================="

  # 首次安装完成后，直接打开一次管理菜单（无需重启 Termux）
  if [ "${FROM_MENU:-0}" != "1" ] && [ -t 0 ]; then
    info "正在打开管理菜单..."
    cmd_menu
  fi
}

# ---------- 启动 ----------
cmd_start() {
  if ! is_installed; then
    error "尚未安装 SillyTavern，请先运行: bash st.sh install"
    return 1
  fi
  if [ ! -d "$ST_DIR/node_modules" ]; then
    info "检测到依赖未安装，正在安装 (npm install)..."
    (cd "$ST_DIR" && npm install --no-audit --no-fund) || { error "npm install 失败。"; return 1; }
  fi
  info "启动 SillyTavern，请用浏览器访问 http://127.0.0.1:${PORT}"
  info "按 Ctrl+C 停止服务。"
  cd "$ST_DIR" && node server.js
}

# ---------- 更新 ----------
cmd_update() {
  if ! is_installed; then
    error "尚未安装 SillyTavern，请先运行: bash st.sh install"
    return 1
  fi
  info "拉取最新代码..."
  (cd "$ST_DIR" && git pull --ff-only) || { error "更新失败，请检查网络或本地文件改动。"; return 1; }
  info "更新依赖 (npm install)..."
  (cd "$ST_DIR" && npm install --no-audit --no-fund) || { error "npm install 失败。"; return 1; }
  # 同步更新管理脚本本体
  if [ "$GITHUB_USER" != "你的GitHub用户名" ]; then
    curl -fsSL "$BASE_URL/st.sh" -o "$HOME/st.sh" 2>/dev/null && chmod +x "$HOME/st.sh" && info "管理脚本已同步到最新版"
  fi
  info "更新完成！"
}

# ---------- 卸载 ----------
cmd_uninstall() {
  if ! is_installed; then
    error "未检测到 SillyTavern 安装（$ST_DIR 不存在）。"
    return 1
  fi
  warn "卸载将删除 $ST_DIR 目录，包括所有聊天记录、角色卡、世界书等数据（不可恢复！）"
  if confirm "确定要卸载吗？"; then
    rm -rf "$ST_DIR"
    info "已删除 $ST_DIR"
    if [ -f "$HOME/st.sh" ] && confirm "是否同时删除管理脚本 ~/st.sh ?"; then
      rm -f "$HOME/st.sh"
      info "已删除 ~/st.sh"
    fi
    info "卸载完成。依赖 (nodejs-lts, git) 已保留，如需一并移除:"
    info "  pkg uninstall nodejs-lts git"
  else
    warn "已取消卸载。"
  fi
}

# ---------- 状态 ----------
cmd_status() {
  echo "---- 系统信息 ----"
  echo "架构:        $(uname -m)"
  echo "Node.js:     $(node --version 2>/dev/null || echo '未安装')"
  echo "npm:         $(npm --version 2>/dev/null || echo '未安装')"
  if is_installed; then
    echo "SillyTavern: 已安装"
    echo "安装目录:    $ST_DIR"
    echo "当前版本:    $(git -C "$ST_DIR" log -1 --format='%h %cs %s' 2>/dev/null)"
    echo "监听地址:    http://127.0.0.1:${PORT}"
  else
    echo "SillyTavern: 未安装"
  fi
}

# ---------- Termux 自启动 ----------
# 原理：向 ~/.bashrc 写入一段配置，每次打开 Termux 时自动执行。
# 用带标记的代码块管理，可随时开启/关闭/切换模式。

autostart_is_on() {
  [ -f "$HOME/.bashrc" ] && grep -q "$AUTOSTART_BEGIN" "$HOME/.bashrc"
}

# 用纯 bash 删除 ~/.bashrc 中的自启动配置块（避免依赖 sed）
autostart_remove() {
  if [ -f "$HOME/.bashrc" ] && autostart_is_on; then
    local tmp line skip=0
    tmp="$HOME/.bashrc.st.tmp"
    : > "$tmp"
    while IFS= read -r line; do
      if [ "$line" = "$AUTOSTART_BEGIN" ]; then
        skip=1
      fi
      if [ "$skip" = "0" ]; then
        printf '%s\n' "$line" >> "$tmp"
      fi
      if [ "$line" = "$AUTOSTART_END" ]; then
        skip=0
      fi
    done < "$HOME/.bashrc"
    mv "$tmp" "$HOME/.bashrc"
    info "已清除旧的自动启动配置。"
  fi
}

# $1 = menu（默认）| direct
autostart_write() {
  autostart_remove
  {
    echo "$AUTOSTART_BEGIN"
    echo "# 由 st.sh 自动管理，请勿手动修改；临时跳过可执行: export ST_SKIP_AUTOSTART=1"
    echo 'if [ -f "$HOME/st.sh" ] && [ -z "$ST_SKIP_AUTOSTART" ]; then'
    if [ "$1" = "direct" ]; then
      echo '    bash "$HOME/st.sh" start'
    else
      echo '    bash "$HOME/st.sh"'
    fi
    echo 'fi'
    echo "$AUTOSTART_END"
  } >> "$HOME/.bashrc"
}

# 自启动设置（支持命令行参数或交互子菜单）
cmd_autostart() {
  local mode="${1:-}"
  case "$mode" in
    on)
      autostart_write menu
      info "已开启自启动（管理菜单模式），下次打开 Termux 生效。"
      return
      ;;
    direct)
      autostart_write direct
      info "已开启自启动（直接启动模式），下次打开 Termux 生效。"
      return
      ;;
    off)
      autostart_remove
      info "已关闭自启动。"
      return
      ;;
    status)
      if autostart_is_on; then
        if grep -q 'st.sh" start' "$HOME/.bashrc"; then
          echo "已开启（打开 Termux 直接启动 SillyTavern）"
        else
          echo "已开启（打开 Termux 显示管理菜单）"
        fi
      else
        echo "未开启"
      fi
      return
      ;;
    "") ;; # 进入交互子菜单
    *)
      warn "未知参数: $1"
      return 1
      ;;
  esac

  while true; do
    echo
    echo "===== Termux 自启动设置 ====="
    if autostart_is_on; then
      if grep -q 'st.sh" start' "$HOME/.bashrc"; then
        echo "当前状态: 已开启（打开 Termux 直接启动 SillyTavern）"
      else
        echo "当前状态: 已开启（打开 Termux 显示管理菜单）"
      fi
    else
      echo "当前状态: 未开启"
    fi
    echo "  1) 开启：打开 Termux 自动显示管理菜单"
    echo "  2) 开启：打开 Termux 直接启动 SillyTavern"
    echo "  3) 关闭自启动"
    echo "  0) 返回"
    echo "--------------------------------------"
    read -r -p "请选择: " choice
    case "$choice" in
      1)
        autostart_write menu
        info "已开启自启动（管理菜单模式），下次打开 Termux 生效。"
        ;;
      2)
        autostart_write direct
        info "已开启自启动（直接启动模式），下次打开 Termux 生效。"
        ;;
      3)
        autostart_remove
        info "已关闭自启动。"
        ;;
      0) return ;;
      *) warn "无效选择，请重新输入。" ;;
    esac
  done
}

# ---------- 交互式菜单 ----------
cmd_menu() {
  while true; do
    echo
    echo "======================================"
    echo "    SillyTavern 管理菜单 (Termux)"
    echo "======================================"
    if is_installed; then
      echo "  1) 启动 SillyTavern"
      echo "  2) 更新 SillyTavern"
      echo "  3) 卸载 SillyTavern"
      echo "  4) 查看状态信息"
      echo "  5) 设置 Termux 自启动"
    else
      echo "  1) 一键安装 SillyTavern"
      echo "  2) 查看状态信息"
      echo "  5) 设置 Termux 自启动"
    fi
    echo "  0) 退出"
    echo "--------------------------------------"
    read -r -p "请选择: " choice
    case "$choice" in
      1)
        if is_installed; then cmd_start; else FROM_MENU=1 cmd_install; fi
        ;;
      2)
        if is_installed; then cmd_update; else cmd_status; fi
        ;;
      3) cmd_uninstall ;;
      4) cmd_status ;;
      5) cmd_autostart ;;
      0)
        echo "再见！"
        break
        ;;
      *) warn "无效选择，请重新输入。" ;;
    esac
  done
}

# ---------- 入口 ----------
usage() {
  echo "用法: bash st.sh [命令]"
  echo
  echo "命令:"
  echo "  (无参数)    打开交互式管理菜单"
  echo "  install     一键安装 SillyTavern"
  echo "  start       启动 SillyTavern"
  echo "  update      更新 SillyTavern"
  echo "  uninstall   卸载 SillyTavern"
  echo "  status      查看状态信息"
  echo "  autostart   设置 Termux 自启动（可用参数: on/direct/off/status）"
  echo "  help        显示本帮助"
}

main() {
  case "${1:-}" in
    "")
      if [ "${NONINTERACTIVE:-0}" = "1" ]; then
        cmd_install
      else
        cmd_menu
      fi
      ;;
    install)   cmd_install ;;
    start)     cmd_start ;;
    update)    cmd_update ;;
    uninstall) cmd_uninstall ;;
    status|info) cmd_status ;;
    autostart) cmd_autostart "${2:-}" ;;
    help|-h|--help) usage ;;
    *)
      warn "未知命令: $1"
      usage
      exit 1
      ;;
  esac
}

main "$@"

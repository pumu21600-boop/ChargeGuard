#!/sbin/sh
# 静默安装：不输出 ui_print
# KSU 执行本脚本时 MODPATH 指向模块目录
D="${MODPATH:-${0%/*}}"

chmod 755 "$D/service.sh" 2>/dev/null
chmod 755 "$D/daemon.sh" 2>/dev/null
chmod 755 "$D/uninstall.sh" 2>/dev/null
chmod 755 "$D/webroot" 2>/dev/null
chmod 644 "$D/webroot/index.html" 2>/dev/null
chmod 644 "$D/module.prop" 2>/dev/null

exit 0
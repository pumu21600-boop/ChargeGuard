#!/system/bin/sh
# KSU service 阶段入口：只负责后台拉起 daemon，自己立即退出
MODDIR=${0%/*}
LOG=/data/local/tmp/coolcharge.state
STOP=/data/local/tmp/coolcharge.stop
PIDF=/data/local/tmp/coolcharge.pid

rm -f $STOP $LOG

# 防重入：查 PID 文件（精确，不做模糊匹配）
if [ -f $PIDF ]; then
  for p in $(cat $PIDF); do
    [ "$p" = "$$" ] && continue
    kill -0 "$p" 2>/dev/null || continue
    cmd=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null)
    case "$cmd" in
      *"sh $MODDIR/daemon.sh"*)
        echo "daemon already running: $p" > $LOG
        exit 0
        ;;
    esac
  done
fi

setsid sh $MODDIR/daemon.sh >/dev/null 2>&1 &
exit 0
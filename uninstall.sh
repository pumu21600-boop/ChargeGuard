#!/system/bin/sh
# 卸载时停掉守护进程
# 只用 PID 文件精确杀 + cmdline 复核，绝不做 pgrep -f 子串匹配（会误杀无关进程）
PIDF=/data/local/tmp/coolcharge.pid
MODDIR=$(dirname "$0")
touch /data/local/tmp/coolcharge.stop 2>/dev/null

real_pids() {
  # 输出"PID文件里的pid + cmdline 确实匹配"的进程
  for p in $(cat $PIDF 2>/dev/null); do
    [ -z "$p" ] && continue
    [ "$p" = "$$" ] && continue
    kill -0 "$p" 2>/dev/null || continue
    cmd=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null)
    case "$cmd" in
      *"sh $MODDIR/daemon.sh"*) echo "$p" ;;
    esac
  done
}

# 温和杀：先 TERM，等最多 5 秒
i=0
while [ $i -lt 5 ]; do
  pids=$(real_pids)
  [ -z "$pids" ] && break
  for p in $pids; do kill "$p" 2>/dev/null; done
  sleep 1
  i=$((i+1))
done

# 兜底：还活着就 KILL
for p in $(real_pids); do kill -9 "$p" 2>/dev/null; done

rm -f $PIDF
rm -f /data/local/tmp/coolcharge.stop
rm -f /data/local/tmp/coolcharge.state
rm -f /data/local/tmp/coolcharge.exit
exit 0
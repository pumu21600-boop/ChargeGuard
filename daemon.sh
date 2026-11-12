#!/system/bin/sh
# ChargeGuard 守护进程本体（由 service.sh 后台拉起）
CD=/sys/devices/virtual/oplus_chg/battery/cool_down
BT=/sys/class/power_supply/battery/temp
USB=/sys/class/power_supply/usb/online
STOP=/data/local/tmp/coolcharge.stop
ON=480
OFF=520
LOG=/data/local/tmp/coolcharge.state
EXITLOG=/data/local/tmp/coolcharge.exit
CONF="$0"

# 记录退出原因，便于排查
trap 'rm -f /data/local/tmp/coolcharge.pid; echo "$(date +%s) code=$? state=$state loop=$n" >> $EXITLOG 2>/dev/null' EXIT INT TERM

# 开机时充电驱动可能尚未就绪，等待节点出现而不是直接退出
i=0
while [ ! -f $CD ]; do
  i=$((i+1))
  [ $i -gt 60 ] && exit 0
  sleep 2
done
[ -f $STOP ] && rm -f $STOP
# PID 文件：卸载/停止靠它精确杀进程，杜绝模糊匹配误伤
echo $$ > /data/local/tmp/coolcharge.pid
state=0
n=0
while :; do
n=$((n+1))
[ -f $STOP ] && break
# 热加载阈值：读模块内配置文件，改完立即生效
a=$(grep -m1 "^ON=" "$CONF" 2>/dev/null | cut -d= -f2)
b=$(grep -m1 "^OFF=" "$CONF" 2>/dev/null | cut -d= -f2)
case "$a$b" in ""|*[!0-9]*) ;; *) ON=$a; OFF=$b ;; esac
t=`cat $BT 2>/dev/null`
on=`cat $USB 2>/dev/null`
case "$t$on" in
''|*[!0-9]*) state=0; continue ;;
esac
if [ "$on" = 1 ]; then
if [ $state = 0 ] && [ $t -lt $ON ]; then state=1
elif [ $state = 1 ] && [ $t -ge $OFF ]; then state=0
fi
# 每秒无条件压一次，不给温控服务留覆盖窗口
[ $state = 1 ] && echo 0 > $CD 2>/dev/null
else
state=0
fi
# state 温度 心跳时间戳（WebUI 靠时间戳判活，不再信残留文件）
echo "$state $t $(date +%s)" > $LOG 2>/dev/null
sleep 1
done
echo "stopped $(date +%s)" > $LOG 2>/dev/null
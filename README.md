# ChargeGuard

充电守护 —— 面向 OnePlus / OPPO / realme（ColorOS 系）机型的 Magisk / KernelSU 模块。
系统温控在电池温度升高时会向充电驱动下发 `cool_down=1`，充电功率随即被限到很低。本模块按温度迟滞自动接管这个节点：**低温强制放开、高温交还系统**，防止充电被莫名锁功率。

> 模块 ID 为 `CoolCharge`（历史命名），安装路径以它为准；仓库按模块显示名 ChargeGuard 命名。

## 特性

- **迟滞控制**：温度低于 ON（默认 48.0℃）时每秒强制写 `cool_down=0`；高于 OFF（默认 52.0℃）后停止接管，交还系统温控。两阈值之间为缓冲区，状态不反复横跳。
- **KernelSU WebUI**：实时显示电池温度 / 功率 / 电流 / 电压 / cool_down / 插线状态；滑条调 ON / OFF 阈值，保存即热加载生效，无需重启；支持重启 / 停止 / 启动守护进程。
- **热加载**：阈值就存在模块自身的 `daemon.sh` 里，运行中的循环每秒重读，改完立即生效。
- **精确进程管理**：只靠 PID 文件 + `/proc` cmdline 复核停进程，绝不做子串匹配误杀无关进程。
- **心跳判活**：状态文件每秒写入时间戳，WebUI 超过 5 秒读不到新鲜心跳即判守护已死，不被残留文件误导。
- **卸载干净**：TERM → KILL 依次停守护，并清理全部临时状态文件。

## 工作原理

```text
/sys/devices/virtual/oplus_chg/battery/cool_down   ← 接管目标（写 0 = 不限流）
/sys/class/power_supply/battery/temp               ← 电池温度（单位 0.1℃）
/sys/class/power_supply/usb/online                 ← 是否插线
```

`service.sh` 在 service 阶段用 `setsid` 后台拉起 `daemon.sh` 后立即退出；`daemon.sh` 每秒一轮：

1. 插线且温度 < ON → 强制写 `cool_down=0`（每秒压一次，不给温控服务留覆盖窗口）；
2. 插线且温度 ≥ OFF → 停止写入，系统温控恢复主导；
3. 未插线 → 状态归零；
4. 将 `状态 温度 心跳时间戳` 写入状态文件供 WebUI 判断存活。

## 兼容性

| 管理器 | 模块运行 | WebUI |
|---|---|---|
| KernelSU 及其衍生 | ✅ | ✅ 完整功能 |
| Magisk（v20.4+） | ✅ | ❌ 无 WebUI，改阈值见下 |

仅适用于搭载 oplus 充电驱动的机型（一加 / OPPO / realme）。系统里没有 `/sys/devices/virtual/oplus_chg/battery/cool_down` 节点时模块不会生效（守护进程会等待节点出现，最多约 2 分钟后自行退出）。

## 安装

1. 在 [Releases](../../releases) 下载 `ChargeGuard-v1.0.0.zip`
   （SHA256 `26b10e4c8c72d79a1282d3d1bf86709200955597a79471f455db3ebd31149c49`）；
2. 管理器 → 模块 → 从存储安装；
3. 重启手机（service 阶段自动拉起守护进程）；
4. KernelSU 用户在管理器模块页点「WebUI」打开控制面板。

### Magisk 下改阈值

Magisk 没有 WebUI，用任意 root 文件编辑器打开
`/data/adb/modules/CoolCharge/daemon.sh`，改开头两行（单位 0.1℃），保存即热加载生效：

```sh
ON=480   # 48.0℃：低于此温度强制放开限流
OFF=520  # 52.0℃：高于此温度交还系统温控
```

## 数据文件

| 路径 | 用途 |
|---|---|
| `/data/adb/modules/CoolCharge/daemon.sh` | 运行脚本，兼作阈值配置 |
| `/data/local/tmp/coolcharge.state` | 状态 温度 心跳时间戳 |
| `/data/local/tmp/coolcharge.pid` | 守护进程 PID |
| `/data/local/tmp/coolcharge.stop` | 停止标记 |
| `/data/local/tmp/coolcharge.exit` | 退出原因记录 |

## 卸载

在管理器中移除模块即可，卸载脚本会自动停止守护并清理上述临时文件。

## 免责声明

本模块改变的是厂商温控的保守限流策略：OFF 阈值以内电池将以更高功率充电，并不保证能有高功率充电的效果，适合遇到锁5w问题又不追求极致快充，长期可能加速电池老化。是否使用、阈值如何取舍由你自行判断，作者不对任何电池或硬件损耗负责。

## 许可

[MIT](LICENSE)

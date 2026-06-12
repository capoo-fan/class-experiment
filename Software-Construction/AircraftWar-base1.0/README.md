# AircraftWar

## 编译运行说明（macOS）

本项目是纯 Java 工程，不依赖 Maven 或 Gradle。

### 1. 环境要求

- macOS
- 已安装 JDK（建议 17+）
- 可用的终端（Terminal / iTerm）

检查 Java 环境：

	java -version
	javac -version

### 2. 进入项目目录

在终端执行：

	cd /Users/qianfu/class-experiment/Software-Construction/AircraftWar-base1.0

说明：
- 必须在项目根目录运行。
- 项目中的图片资源按相对路径 src/images 读取，如果在其他目录启动，可能出现图片加载失败。

### 3. 编译

创建输出目录并编译所有 Java 源码：

	mkdir -p out
	find src -name "*.java" | xargs javac -encoding UTF-8 -d out

### 4. 运行

启动主程序：

	java -cp out edu.hitsz.application.Main

正常情况下会看到：
- 终端输出 Hello Aircraft War
- 游戏窗口弹出（标题 Aircraft War）

### 5. 功能测试建议（手工）

可按下面顺序快速验证：

1. 启动游戏后，窗口正常显示，背景滚动。
2. 鼠标拖动时，英雄机随鼠标移动。
3. 英雄机会自动发射子弹并击毁敌机，分数上升。
4. 拾取道具时，终端有对应日志（如 BloodSupply active!）。
5. 英雄机生命值归零后，终端打印 Game Over!。

### 6. 清理与重新编译

如果需要干净重编译：

	rm -rf out
	mkdir -p out
	find src -name "*.java" | xargs javac -encoding UTF-8 -d out

### 7. 常见问题

1) 提示找不到主类

- 先确认已经执行过编译命令。
- 再确认运行命令中的类名是否为 edu.hitsz.application.Main。

2) 图片不显示或程序退出

- 确认当前路径在项目根目录。
- 确认 src/images 目录存在且资源文件完整。

3) macOS 图形相关日志

- 运行时可能出现 TSM/CapsLock 相关系统日志，通常不影响游戏运行。
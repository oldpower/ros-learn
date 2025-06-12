## 1、创建Docker镜像

### 1.1 拉取基础镜像
#### 使用官方ROS Docker镜像

官方提供的ROS Docker镜像分为不同的版本和特性集，例如基础版（ros-core）、桌面版（desktop）等。以下是拉取不同ROS 2发行版桌面完整版镜像的例子：

- 对于ROS 2 Humble Hawksbill：
    ```bash
    docker pull ros:humble-desktop
    ```

- 对于ROS 2 Foxy Fitzroy：
    ```bash
    docker pull ros:foxy-desktop
    ```

- 对于ROS 1 Noetic Ninjemys（最后一个支持的ROS 1版本）：
    ```bash
    docker pull ros:noetic-robot
    ```

如果需要启动一个容器来使用这些镜像，可以使用如下命令：

```bash
docker run -it ros:humble-desktop
```
### 1.2 配置Docker镜像
#### SSH
也可以参考:[SSH配置](./assets/doc/ssh配置.md)的`2,3,4,5`部分。
```bash
apt-get update
apt-get install -y openssh-server
# 确保SSH服务所需的目录存在
mkdir -p /var/run/sshd
# 配置SSH服务
vim /etc/ssh/sshd_config
Port 22                     # SSH端口
PermitRootLogin yes         # 允许root登录（测试环境）
PasswordAuthentication yes  # 启用密码认证
UseDNS no                   # 禁用DNS查询，加快登录速度
# 设置root密码（如果未设置）
passwd root
# 生成SSH密钥（如果缺失）
ssh-keygen -A
# 启动SSH服务
/usr/sbin/sshd -D &
```
- `-D` 选项表示以非守护进程模式运行（便于在前台查看日志）。
- `&` 符号将命令放到后台执行，避免阻塞终端。
```bash
# 验证SSH服务是否运行
ps aux | grep sshd
# 应该看到类似输出：
# root      1234  0.0  0.1  33320  4560 ?        Ss   12:34   0:00 /usr/sbin/sshd -D

# 检查端口监听：
netstat -tulpn | grep :22
# 应该看到类似输出：
# tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      1234/sshd
```
   - 生产环境建议禁用root登录，改用普通用户：
     ```conf
     PermitRootLogin no
     AllowUsers your_username
     ```

#### 启动脚本
```bash
run_docker.sh
```
说明：


## 2、Docker启动后
### 2.1 系统支持中文设置
#### 在 Linux 中检查当前终端编码：
```bash
echo $LANG
```
应该看到类似：
```
en_US.UTF-8
zh_CN.UTF-8
```
如果不是，需要修改语言环境为 UTF-8 支持中文
#### 修改方法
```bash
sudo apt update
sudo apt install language-pack-zh-hans
sudo locale-gen zh_CN.UTF-8
# echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc
export LANG=zh_CN.UTF-8
source ~/.bashrc
```

### 2.2 创建工作空间

#### 🧱 1. `catkin_make` 的本质

`catkin_make` 是 ROS 1 中用于构建 **Catkin 工作空间** 的命令行工具，它是对标准 CMake 构建系统的封装，目的是让 ROS 包的编译更加方便统一。它的主要功能包括：

| 功能 | 说明 |
|------|------|
| 初始化工作空间 | 如果是第一次运行，在当前目录下创建 `build/` 和 `devel/` 目录 |
| 编译ROS包 | 找到 `src/` 目录下的所有 ROS 包，并按照依赖顺序进行编译 |
| 生成环境变量脚本 | 在 `devel/` 目录中生成 `setup.bash` 等文件，让你可以使用ROS命令加载环境 |


#### 📁 2. Catkin 工作空间结构

运行 `catkin_make` 时，它会期望以下目录结构：

```
workspace/
├── src/            <-- 所有 ROS package 放在这里
│   └── my_package/
├── build/          <-- 编译中间文件存放位置
└── devel/          <-- 编译后的可执行文件和环境设置脚本
```

所以，**`catkin_make` 不是创建“单个ROS项目”（包），而是构建整个ROS开发环境的工作空间**。你可以在这个工作空间里放多个ROS包。


#### 🧩 3. 创建一个 ROS Package（这才是“ROS项目模板”）

如果你想要创建一个 ROS 包（也就是一个“ROS项目”），你需要在 `src/` 目录下运行：

```bash
cd ~/workspace/src
catkin_create_pkg my_first_package rospy std_msgs
```

这会创建一个名为 `my_first_package` 的ROS包，依赖于 `rospy` 和 `std_msgs`。

这个包的结构如下：

```
my_first_package/
├── CMakeLists.txt    <-- 编译配置文件
├── package.xml       <-- 包描述文件（元信息、依赖）
└── (可选) src/, scripts/, launch/, msg/ 等目录
```



#### 🛠️ 4. 总结：`catkin_make` vs `catkin_create_pkg`

| 命令 | 用途 | 示例 |
|------|------|------|
| `catkin_make` | 构建整个工作空间，管理多个ROS包的编译 | `cd ~/catkin_ws && catkin_make` |
| `catkin_create_pkg` | 创建一个新的ROS包（项目） | `cd src && catkin_create_pkg my_pkg rospy std_msgs` |

---

#### ✅ 小建议：推荐的标准流程

```bash
# 1. 创建工作空间
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws

# 2. 初始化并构建空工作空间
catkin_make

# 3. 激活环境
source devel/setup.bash

# 4. 创建第一个ROS包
cd src
catkin_create_pkg my_first_package rospy std_msgs

# 5. 回到工作空间根目录再次构建
cd ..
catkin_make

# 6. 开始编写节点代码吧！
```

### 2.3 运行Demo

#### CMakeList.txt

```cmake
# 确保包含下面内容：
find_package(catkin REQUIRED COMPONENTS
  roscpp
  std_msgs
)

catkin_package()

include_directories(
  ${catkin_INCLUDE_DIRS}
)

add_executable(Hello_pub
  src/Hello_pub.cpp
)
add_executable(Hello_sub
  src/Hello_sub.cpp
)

target_link_libraries(Hello_pub
  ${catkin_LIBRARIES}
)
target_link_libraries(Hello_sub
  ${catkin_LIBRARIES}
)
```
#### 🧱编译
```bash
# 回到项目根目录catkin_ws下
catkin_make
```
成功编译后，在`devel/lib/my_first_package/`目录下可看到：
```bash
Hello_pub
Hello_sub
```
#### ▶️运行

1. 启动 `roscore`（在一个终端中运行）：

```bash
roscore
```

2. 打开第二个终端，运行发布者：

```bash
source devel/setup.bash
rosrun my_first_package Hello_pub

[INFO] [1749701382.271941675]: 发送的消息:Hello 你好！18
[INFO] [1749701383.272046000]: 发送的消息:Hello 你好！19
```

3. 打开第三个终端，运行订阅者：

```bash
source devel/setup.bash
rosrun my_first_package Hello_sub

[INFO] [1749701382.272759332]: 我听见:Hello 你好！18
[INFO] [1749701383.272496380]: 我听见:Hello 你好！19
```

#### ✅ 总结：你需要做的事

| 步骤 | 命令 |
|------|------|
| 创建 src 目录 | `mkdir -p ~/catkin_ws/src/my_first_package/src` |
| 移动代码文件 | `mv Hello_hub.cpp Hello_sub.cpp src/` |
| 修改 CMakeLists.txt | 添加 `add_executable(...)` 和 `target_link_libraries(...)` |
| 修改 package.xml | 添加 `<depend>roscpp</depend>` 和 `<depend>std_msgs</depend>` |
| 编译 | `cd ~/catkin_ws && catkin_make` |
| 激活环境 | `source devel/setup.bash` |
| 启动核心 | `roscore` |
| 启动发布者 | `rosrun my_first_package Hello_hub` |
| 启动订阅者 | `rosrun my_first_package Hello_sub` |


---

## 参考链接
[ROSTutorials](http://www.autolabor.com.cn/book/ROSTutorials/)



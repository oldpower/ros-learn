#!/bin/bash

# ========================
# 配置部分（可根据需要修改）
# ========================
CONTAINER_NAME="ros1.1"
IMAGE_NAME="ros1:v1.0"
HOST_SSH_PORT="2223"
DISPLAY_SOCKET="/tmp/.X11-unix"

# ========================
# 步骤 1: 检查 DISPLAY 是否设置
# ========================
if [ -z "$DISPLAY" ]; then
    echo "[-] DISPLAY 环境变量未设置。尝试自动获取..."
    # 尝试从 resolv.conf 获取 WSLg 的 DISPLAY 地址
    GATEWAY_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
    if [ -n "$GATEWAY_IP" ]; then
        export DISPLAY=$GATEWAY_IP:0
        echo "[+] 自动设置 DISPLAY=$DISPLAY"
    else
        echo "[-] 无法自动获取 DISPLAY，你需要手动设置或检查是否在 WSL2 中运行。"
        exit 1
    fi
fi

# ========================
# 步骤 2: 允许 X11 访问（安全起见只允许 root）
# ========================
echo "[*] 授权 X11 访问权限..."
# xhost local:root > /dev/null 2>&1
xhost +local:

# ========================
# 步骤 3: 删除已存在的同名容器（如果有的话）
# ========================
if docker inspect $CONTAINER_NAME > /dev/null 2>&1; then
    echo "[*] 容器 $CONTAINER_NAME 已存在，正在删除..."
    docker rm -f $CONTAINER_NAME
else
    echo "[*] 容器 $CONTAINER_NAME 不存在，跳过删除步骤。"
fi

# ========================
# 步骤 4: 创建并启动容器
# ========================
echo "[*] 正在创建容器 $CONTAINER_NAME ..."

# -v $DISPLAY_SOCKET:$DISPLAY_SOCKET \
docker run -itd \
  --name $CONTAINER_NAME \
  --hostname ros1 \
  -p $HOST_SSH_PORT:22 \
  -e DISPLAY=$DISPLAY \
  -v /mnt/wslg/.X11-unix:/tmp/.X11-unix \
  -v /mnt/d/wsl_workspace/workspace:/home/ros1/workspace \
  -e QT_X11_NO_MITSHM=1 \
  $IMAGE_NAME \
  /bin/bash -c "echo 'export DISPLAY=:0' >> /home/ros1/.bashrc && echo 'source /opt/ros/noetic/setup.bash' >> /home/ros1/.bashrc && /usr/sbin/sshd -D & exec /bin/bash"

  # /bin/bash -c "/usr/sbin/sshd -D & /bin/bash"

# ========================
# 步骤 5: 提示用户如何使用
# ========================
echo ""
echo "[+] 容器已成功运行！你可以通过以下方式连接："
echo "    ssh root@localhost -p $HOST_SSH_PORT"
echo ""
echo "[i] 如果你想进入容器终端，请运行："
echo "    docker exec -it $CONTAINER_NAME /bin/bash"

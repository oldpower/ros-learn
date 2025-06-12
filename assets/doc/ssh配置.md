以下是在Docker容器内配置SSH服务，允许root和普通用户ros1从外部网络连接的**完整步骤**：


### **1. 进入Docker容器**
如果尚未进入容器，使用以下命令进入：
```bash
docker exec -it <容器ID或名称> /bin/bash
```


### **2. 安装OpenSSH服务器**
```bash
# 对于Debian/Ubuntu镜像
apt-get update && apt-get install -y openssh-server

# 对于Alpine镜像
apk update && apk add openssh
```


### **3. 创建普通用户 `ros1`**
```bash
adduser --disabled-password --gecos "" ros1
passwd ros1  # 设置密码（例如：ros1234）
```


### **4. 配置SSH服务**
#### **4.1 修改 `sshd_config`**
```bash
vim /etc/ssh/sshd_config
```
确保以下配置存在（删除注释或修改现有行）：
```conf
Port 22                     # SSH端口
PermitRootLogin yes         # 允许root登录
PasswordAuthentication yes  # 启用密码认证
AllowUsers root ros1        # 仅允许root和ros1用户登录
UseDNS no                   # 禁用DNS查询，加快登录速度
```

#### **4.2 生成SSH密钥（如果缺失）**
```bash
ssh-keygen -A
```


### **5. 启动SSH服务**
```bash
mkdir -p /var/run/sshd
/usr/sbin/sshd -D &  # 后台运行SSH服务
```


### **6. 验证容器内部SSH服务**
```bash
# 检查SSH进程是否运行
ps aux | grep sshd

# 检查端口22是否监听
netstat -tulpn | grep :22
```


### **7. 宿主机配置端口映射**
如果容器尚未启动或需要修改端口映射，使用以下命令启动容器：
```bash
docker run -d -p 2222:22 --name ros-container <镜像名称>
```
- **宿主机端口2222**映射到**容器端口22**。
- 可根据需要修改宿主机端口（如 `3333:22`）。


### **8. 从外部设备连接**
#### **使用root用户连接**
```bash
ssh root@<宿主机IP> -p 2222
```

#### **使用ros1用户连接**
```bash
ssh ros1@<宿主机IP> -p 2222
```
- **宿主机IP**：运行Docker的主机在局域网中的IP地址（如 `192.168.1.100`）。
- 输入之前设置的密码进行登录。


### **9. 故障排查**
1. **检查防火墙**：确保宿主机防火墙允许外部访问端口2222。
   ```bash
   # Ubuntu/Debian
   ufw allow 2222/tcp

   # CentOS/RHEL
   firewall-cmd --add-port=2222/tcp --permanent
   firewall-cmd --reload
   ```

2. **查看SSH日志**：
   ```bash
   tail -f /var/log/auth.log  # Debian/Ubuntu
   tail -f /var/log/secure    # CentOS/RHEL
   ```


### **安全注意事项**
- **生产环境建议**：
  - 禁用root登录（`PermitRootLogin no`）。
  - 使用SSH密钥认证替代密码认证。
- **密码复杂度**：设置强密码，避免使用简单密码。


配置完成后，root和ros1用户均可通过SSH从局域网中的任何设备连接到容器。
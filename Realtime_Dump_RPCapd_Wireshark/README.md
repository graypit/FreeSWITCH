## Real-time SIP-Trace/Capture/Dump via RPCapd and Wireshark

RPCAPD - is a daemon that provides remote traffic capture for Windows version of Wireshark protocol analyzer. It is shipped with WinPcap network capture library for Windows but is absent from libpcap in Linux.


#### Firstly we need install and compile RPCapd:
```bash
$ mkdir -p /var/lib/graypit-lab/
$ cd /var/lib/graypit-lab/
$ git clone https://github.com/rpcapd-linux/rpcapd-linux.git
$ apt-get build-dep libpcap
$ cd rpcapd-linux/libpcap/
$ ./configure && make && cd ../ && make
$ chmod 777 /var/lib/graypit-lab/rpcapd-linux/rpcapd
$ echo "alias rpcapd='/var/lib/graypit-lab/rpcapd-linux/rpcapd'" >> ~/.bashrc
$ source ~/.bashrc
```

- Create  **/etc/systemd/system/rpcapd-procall.service** file and add the following lines:
```bash
[Unit]
Description=RPCapd Capture Tool by GPT
After=network.target
[Service]
WorkingDirectory=/var/lib/graypit-lab/
ExecStart=/bin/bash -c "/var/lib/graypit-lab/rpcapd-linux/rpcapd -4 -n -p 10023 2>&1 >> /var/lib/graypit-lab/rpcapd-linux/rpcapd.log & echo $! > /var/lib/graypit-lab/rpcapd-linux/systemd.pid"
PIDFile=/var/lib/graypit-lab/rpcapd-linux/systemd.pid
Restart=always
Type=simple
User=root
Group=root

[Install]
WantedBy=multi-user.target
```
- Reload systemd and start the service:
```bash
$ systemctl daemon-reload
$ systemctl start rpcapd-procall
# Check the service:
$ systemctl status rpcapd-procall
# You can see service was started on 10023/tcp port
```

- Or you can start the RPCapd manually with e.g 2323/tcp port
```bash
$ rpcapd -4 -n -p 2323
```
#### Install Wireshark on your Laptop and :
- Press **CTRL+K**
- Go to **Manage Interface**
- Go to **Remote Interfaces**
- Click to '**+**' and add the RPCapd server IP address with your port
- Select the your **rpcap://** with your interface adapter and click to **Start**
##### Now you can see the real-time full capture

## FreeSWITCH Corosync & Pacemaker Cluster with DRBD PGSQL
### The Hard-Way

### In this README I'll show you how to **Install/Configure and Test** DRBD PGSQL & Corosync & Pacemaker for the FreeSWITCH Clustering

#### You must Prepare 2 servers wth Debian 9 (Create VMs or use a physical machines)
- **Don't forget ! You need add HDD on both servers with same size (e.g. with Hypervisor)**

##### For example we have :
- 1 Machine - FreeSWITCH node1 with PGSQL - (e.g. `10.234.20.241`)
- 2 Machine - FreeSWITCH node2 with PGSQL - (e.g.`10.234.20.242`)
- And Virtual/Floating IP -  (e.g.`10.234.20.240`)
- New HDD on both servers (e.g.`/dev/sdb`)

##### You should add to your nodes IP addresses into `/etc/hosts` on both FS servers :
```bash
10.234.20.241 node1
10.234.20.242 node2
```
Change your server hostname

- For node1 :
```bash
$ echo 'node1' > /etc/hostname
```
- For node2 :
```bash
$ echo 'node2' > /etc/hostname
```

#### Install DRBD and configure HDD on both FS servers :
```bash
$ apt-get install drbd-utils xfsprogs -y
$ modprobe drbd
$ echo drbd > /etc/modules-load.d/drbd.conf
$ echo -e "g\nn\n\n\n\nt\n8e\nw\n" | fdisk /dev/sdb
$ reboot
```
- For each servers (node1,node2) you will create **/etc/drbd.d/pgsql.res** file and add the following lines:
```java
resource postgres {
 protocol C;
 syncer {rate 100M;}
 startup {
  wfc-timeout 0;
  degr-wfc-timeout
  120;
 }
 disk { on-io-error detach; }
 on node1 {
  device      /dev/drbd0;
  disk        /dev/sdb;
  address     10.234.20.241:7791;
  meta-disk   internal;
 }
 on node2 {
  device      /dev/drbd0;
  disk        /dev/sdb;
  address     10.234.20.242:7791;
  meta-disk   internal;
 }
}
```

- **Configure HDD on both servers:**
```bash
$ mke2fs -j /dev/sdb1 && dd if=/dev/zero bs=1M count=500 of=/dev/sdb1; sync
$ echo -e "yes\n"|drbdadm create-md postgres
```

#### After reboot and install Corosync/Pacemaker on both FS servers :
```bash
$ apt install corosync pacemaker pcs -y 
$ systemctl start pcsd.service && systemctl enable pcsd.service
$ echo -e "123456\n123456\n"|passwd hacluster 2>&1 >/dev/null
$ systemctl stop corosync.service && rm -rf /etc/corosync/corosync.conf 
$ echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
$ sysctl -p
````


- **Configure DRBD on Primary Server (node1):**
```bash
$ echo -e "yes\n"|drbdadm create-md postgres
$ drbdadm up postgres
$ drbdadm -- --overwrite-data-of-peer primary postgres
$ mkfs.xfs -f /dev/drbd0
$ drbdadm primary --force postgres
$ mkdir -p /app/pgsql-procall/ /app/pgsql-procall/pid/ /var/lib/pgsql/ /var/log/pgsql-procall/
$ mount -t xfs /dev/drbd0 /var/lib/pgsql
$ chmod 700 -R /var/lib/pgsql/
$ chmod 777 -R /usr/lib/postgresql/10/bin/
$ chown postgres:postgres -R /app/pgsql-procall/ /var/lib/pgsql/ /var/log/pgsql-procall/ /var/log/postgresql/
```

- **Prepare Secondary Server (node2):**
```bash
$ mkdir -p /app/pgsql-procall/ /app/pgsql-procall/pid/ /var/lib/pgsql/ /var/log/pgsql-procall/
$ chown postgres:postgres -R /app/pgsql-procall/ /var/lib/pgsql/ /var/log/pgsql-procall/ /var/log/postgresql/
$ chmod 777 -R /usr/lib/postgresql/10/bin/
$ chmod 700 -R /var/lib/pgsql/
```

- For each servers (node1,node2) you will create  **/app/pgsql-procall/procall-wait-db.sh** file and add the following lines:
```bash
#!/usr/bin/env bash

while true
do
  if [ ! -z "$(netstat -nltp | grep 8021)" ]
  then
    fs_cli -x 'sofia recover'
    break ; exit 0
  fi
done
```

- Set permissions:
```bash
$ chmod 777 /app/pgsql-procall/procall-wait-db.sh
$ chown postgres:postgres /app/pgsql-procall/procall-wait-db.sh
```

- For each servers (node1,node2) you will create  **/etc/systemd/system/pgsql-procall.service** file and add the following lines:
```bash
[Unit]
Description=Procall Call Recover
After=network.target
[Service]
WorkingDirectory=/app/pgsql-procall/
ExecStartPre=/bin/bash -c "/usr/bin/fs_cli -x 'fsctl crash'"
ExecStart=/bin/bash -c "/usr/lib/postgresql/10/bin/postgres -D /var/lib/pgsql/data 2>&1 >> /var/log/pgsql-procall/pgsql.log & echo $! > /app/pgsql-procall/pid/pgsql.pid"
ExecStartPost=/bin/bash -c "/app/pgsql-procall/procall-wait-db.sh"
PIDFile=/app/pgsql-procall/pid/pgsql.pid
Restart=always
Type=simple
User=postgres
Group=postgres

[Install]
WantedBy=multi-user.target
```

- Then execute the following lines on both servers:
```bash
$ usermod -a -G postgres freeswitch
$ chmod 777 /etc/systemd/system/pgsql-procall.service
$ systemctl daemon-reload && systemctl stop postgresql && systemctl disable postgresql
$ reboot
```

#### Configure PostgreSQL 10 on Primary server (node1 ):

```bash
$ systemctl start drbd && drbdadm primary --force postgres
$ mount -t xfs /dev/drbd0 /var/lib/pgsql
$ su - postgres
$ cd /usr/lib/postgresql/10/bin/ 
$ ./initdb /var/lib/pgsql/data && logout
$ echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf
```
- Add the following lines into **/var/lib/pgsql/data/pg_hba.conf** 
```bash
host    all             all             10.234.20.0/24            md5
```


#### Next some actions you'll execute only in **node1** server:

- **Auth/Setup/Enable the Cluster:**
```bash
$ pcs cluster auth node1 node2 -u hacluster -p '123456' --force
$ pcs cluster setup --force --name fs_cluster node1 node2 && sleep 3
$ pcs cluster enable --all && sleep 7 && pcs cluster start --all
```
- **Disable Stonith/Quorum Policy:**

```bash
$ pcs property set stonith-enabled=false
$ pcs property set no-quorum-policy=ignore
$ pcs resource defaults resource-stickiness=100
$ pcs cluster cib clust_cfg
$ pcs -f clust_cfg property set no-quorum-policy=ignore
$ pcs -f clust_cfg resource defaults resource-stickiness=100
```
- **Create Resource1 - for DRBD Start and Mount for the Corosync:**
```bash
pcs -f clust_cfg resource create drbd_postgres ocf:linbit:drbd drbd_resource=postgres op monitor interval=15s
pcs -f clust_cfg resource master ms_drbd_postgres drbd_postgres master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true
pcs -f clust_cfg resource create postgres_fs ocf:heartbeat:Filesystem params device=/dev/drbd0 directory=/var/lib/pgsql fstype=xfs
```

- **Create Resource2 - for Floating (Virtual IP) for the Corosync:**
```bash
$ pcs -f clust_cfg resource create procall_floating_ip ocf:heartbeat:IPaddr2 ip=10.234.20.240 cidr_netmask=24 op monitor interval=20s
```

- **Create Resource3 - for our Systemd Service for the Corosync:**
```bash
pcs -f clust_cfg resource create pgsql systemd:pgsql-procall op monitor timeout=30s interval=30s  
```
- **Create and Set Resource Group:**
```bash
$ pcs -f clust_cfg resource group add procallgroup postgres_fs procall_floating_ip pgsql
$ pcs -f clust_cfg constraint colocation add procallgroup with ms_drbd_postgres INFINITY with-rsc-role=Master
$ pcs -f clust_cfg constraint order promote ms_drbd_postgres then start procallgroup
```
- **Run the Resources:**
```bash
$ pcs -f clust_cfg constraint && pcs -f clust_cfg resource show && pcs cluster cib-push clust_cfg
```


##### Execute the following lines on the both FS servers then restart them:
```bash
$ systemctl enable corosync pcsd pacemaker
$ reboot
```

##### After restart you can check Primary/Secondary Node (Cluster server with floating IP):
```bash
# Check Online Cluster hosts:
$ pcs status |grep 'Online'
# Check the Primary Cluster:
$ pcs status |grep 'Masters:'
```
##### Create Username & Databases on Primary Node:
```bash
$ su - postgres -c "psql -c \"CREATE DATABASE fssync ;\""
$ su - postgres -c "psql -c \"CREATE USER fssyncuser WITH PASSWORD 'C0r0SyncFS';\""
$ su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE  fssync TO fssyncuser;\""
```

### Configure FreeSWITCH for Call Recovering on both servers (node1,node2):
- Add the following lines into **/etc/freeswitch/autoload_configs/switch.conf.xml**:
```bash
    <param name="switchname" value="procall"/>
    <param name="core-db-dsn" value="pgsql://hostaddr=10.234.20.240 dbname=fssync user=fssyncuser password='C0r0SyncFS' options='-c client_min_messages=NOTICE'" />
    <param name="core-recovery-db-dsn" value="pgsql://hostaddr=10.234.20.240 dbname=fssync user=fssyncuser password='C0r0SyncFS' options='-c client_min_messages=NOTICE'" />
```

- Add the following lines into **/etc/freeswitch/sip_profiles/internal.xml**:
```bash
<param name="track-calls" value="true" />
<param name="odbc-dsn" value="pgsql://hostaddr=10.234.20.240 dbname=fssync user=fssyncuser password='C0r0SyncFS' options='-c client_min_messages=NOTICE'"/>
```
- Add the following lines into **/etc/freeswitch/sip_profiles/external.xml**:
```bash
<param name="track-calls" value="true" />
<param name="odbc-dsn" value="pgsql://hostaddr=10.234.20.240 dbname=fssync user=fssyncuser password='C0r0SyncFS' options='-c client_min_messages=NOTICE'"/>
```

#### Actually you can also add same database connections for all modules. It's your choise
```bash
<param name="odbc-dsn" value="pgsql://hostaddr=10.234.20.240 dbname=fssync user=fssyncuser password='C0r0SyncFS' options='-c client_min_messages=NOTICE'"/>
```
- Change FreeSWITCH IP to the your Virtual cluster IP  into **/etc/freeswitch/vars.xml**:
```bash
<X-PRE-PROCESS cmd="set" data="local_ip_v4=10.234.20.240"/>
```

- Then Restart the FreeSWITCH on both servers:
```bash
systemctl restart freeswitch
```

### Testing :

- Register SIP Number e.g. `1001` in Jitsi on your Laptop and e.g `1002` number in other Laptop
- Make call and answer
- Now you must suddenly shutdown the primary server (with hypervisor or Vcenter)
- If your configs is correct then the voice should migrate to the second server in 2-3 seconds with the PostgreSQL
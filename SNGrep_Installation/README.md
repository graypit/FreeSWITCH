##### SIP Analyze/capture/dump via SNGREP:

##### Install SNGREP Debian 9
```bash
$ apt install sngrep -y
$ echo export NCURSES_NO_UTF8_ACS=1 >> /etc/environment
$ source /etc/environment
$ mkdir -p /var/lib/graypit-lab/dumps/
```
##### Start realtime capture 5060/TCP with all UDP Packets with recording dump to **/var/lib/graypit-lab/dumps/`file`**
```bash
$ sngrep -d ens192 -O /var/lib/graypit-lab/dumps/$(date +'%Y%m%d_%H:%M.pcap') port 5060 and udp
```

##### Start realtime capture e.g SIP Provider IP Address with recording dump to **/var/lib/graypit-lab/dumps/`file`**
```bash
$ sngrep -d ens192 -r -O /var/lib/graypit-lab/dumps/$(date +'%Y%m%d_%H:%M.pcap') host 85.154.22.23
```

##### You can open the dump file in sngrep:
```bash
$ sngrep -I name.pcap
```
- You also can read/troubleshoot/listening_calls PCAP dumpfile in Wireshark.


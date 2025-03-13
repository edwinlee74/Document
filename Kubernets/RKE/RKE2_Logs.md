## System
RKE2 以systemd服務運行,故可以查看syslog的log記錄
```shel
/var/log/syslog
``` 
## Kubelet
可以用PS查看kubelet啟動時所帶參數
```shell
/var/lib/rancher/rke2/agent/logs/kubelet.log
```
## Server
```shell
journalctl -u rke2-server -f
systemctl status rke2-server.service
```
## MISC
```shell
 /var/log/containers
 /var/log/pods
```
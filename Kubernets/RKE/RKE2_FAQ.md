1. NODE重開機時會出現下列訊息.
```shell
ERROR: [transport] Client received GoAway with error code ENHANCE_YOUR_CALM and debug data equal to ASCII "too_many_pings".

 * 原本版本v1.28.15+rke2r1, 升級至v1.31.6+rke2r1後, 此訊息不再發生。
 * 以kubeadm安裝kubernets 1.28.15版本， 並未看見此訊息。
```

2. v1.28.15+rke2r1安裝後會有zombie行程.
```shell
ps axo stat,ppid,pid,comm | grep -w defunct

* v1.31.6+rke2r1不會發生。
* v1.27.15+rke2r1也會發生。
* v1.26.15+rke2r1不會發生。
```

3. 如何檢查憑證日期
```shell
$ echo | openssl s_client -connect localhost:6443 -servername rke-master2 2>/dev/null | openssl x509 -noout -dates
$ openssl x509 -in /var/lib/rancher/rke2/server/tls/client-auth-proxy.crt -noout -dates
```

4. Pod中無法以nvidia-smi查看GPU
```shell
/* runtimeclass.yaml */

apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: nvidia
handler: nvidia
```
![runtimeClassName](/img/runtimeClassName.png)
```shell
/* 在pod中要加進runtimeclassname */
spec:
  runtimeClassName: nvidia
```

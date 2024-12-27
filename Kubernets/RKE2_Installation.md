# RKE2 安裝

> **注意:** 
> - 如果有使用NetworkManager會控制預設網路命名空間介面的路由表,所以會對CNI造成干擾。
> - 因此要將NetworkManager忽略CNI, 不納入管理。
> - 編輯/etc/NetworkManger/conf.d建立一個rke2-canal.conf設定檔。
>
> ```INI
>    [keyfile]
>    unmanaged-devices=interface-name:cali*;interface-name:flannel*
> ```

## 安裝環境變數
| Environment Variable    | Description |
| ------------------------| ----------- |
| INSTALL_RKE2_VERSION    | Version of RKE2 to download from GitHub. Will attempt to download the latest release from the stable channel if not specified. INSTALL_RKE2_CHANNEL should also be set if installing on an RPM-based system and the desired version does not exist in the stable channel.   |
| INSTALL_RKE2_TYPE       | Type of systemd service to create, can be either "server" or "agent" Default is "server".        |
| INSTALL_RKE2_CHANNEL_URL| Channel URL for fetching RKE2 download URL. Defaults to https://update.rke2.io/v1-release/channels.|
| INSTALL_RKE2_CHANNEL    | Channel to use for fetching RKE2 download URL. Defaults to stable. Options include: stable, latest, testing. |
| INSTALL_RKE2_METHOD     | Method of installation to use. Default is on RPM-based systems rpm, all else tar. |

## 安裝方法
安裝方法可以使用tar ball及RPM套件二種方法安裝, 官方有提供安裝scirpt, 可直接下載。
```shell
   curl -sfL https://get.rke2.io --output install.sh
   chmod +x install.sh
```
指定安裝版本:
```shell
   ## script會檢查環境, 如不能用RPM安裝,會下載tar ball。
   curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.28.15+rke2r1 sh -

   ## tar ball內容會解壓縮到/usr/local目錄下
   目錄結構如下:
     - bin: 包含rke2可執行檔及rke2-killall.sh、rke2-uninstall.sh script。
     - lib: 包含server及agent 的systemd檔案。
     - share: 包含RKE2的license及CIS模式下使用的sysctl設定檔。

   ## 要成為server節點(Control Plane), 可直接啟用rke2-server服務
   systemctl enable rke2-server.service
   systemctl start rke2-server.service
   journalctl -u rke2-server -f     # 查看日誌

   ## 啟用後會將其他工具程式放至/var/lib/rancher/rke2/bin目錄下, 如kubectl。
   ## 可將工具程式export至PATH環境變數中或加進你的profile。
   export PATH=$PATH:/var/lib/rancher/rke2/bin

   ## kubeconfig檔會在/etc/rancher/rke2/rke2.yaml, 可直接copy到個人目錄下的.kube目錄
   mkdir .kube
   sudo cp /etc/rancher/rke2/rke2.yaml .kube/config
   sudo chown ${whoami}:${whoami} .kube/config

   ## 使用kubectl工具程式, 查看目前的元件狀態
    kubectl get componentstatuses

   -----------------------------------------------------------------------
   Warning: v1 ComponentStatus is deprecated in v1.19+
   NAME                 STATUS    MESSAGE   ERROR
   controller-manager   Healthy   ok
   scheduler            Healthy   ok
   etcd-0               Healthy   ok

   ## 要構建HA cluster, 可重覆上面的安裝script
   ## 啟動服務前, 可編輯一個/etc/rancher/rke2/config.yaml配置檔
   server: https://{master_IP}:9345   # port 9345為rke2 node和server通信埠
   token: my-shared-token   # 從先前node中的/var/lib/rancher/rke2/server/token取得
   tls-san:
     - {tls server1 IP }
     - {tls server2 IP }
     - {FQDN}

   ## 檢查是否已加入cluster
   kubectl get nodes

   --------------------------------------------------------------------------
   NAME         STATUS   ROLES                       AGE     VERSION
   rke-master   Ready    control-plane,etcd,master   119m    v1.28.15+rke2r1
   rke-node1    Ready    control-plane,etcd,master   2m29s   v1.28.15+rke2r1
```

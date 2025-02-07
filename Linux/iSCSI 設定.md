# #iSCSI target 設定
## OS: Ubuntu 24.04

### 1. 確認所要做為提供空間的硬碟, 以被OS識別。
```shell
       # lsblk
```
### 2. 安裝所需套件。
```shell
       # apt install targetcli-fb
       # systemctl enable rtslib-fb-targetctl
       # systemctl start rtslib-fb-targetctl
```
### 3. 創建一個後端儲存空間
```shell
       === 以targetcli 指令來進行設定
       # targetcli
       # cd backstores/block
       # create name=iscsi_disk01 dev=/dev/sdb
```

### 4. 建立一個iSCSI target
```shell
       # cd /
       # cd iscsi
       # create iqn.2024-12.com.edwin:target01
```
### 5. 指定一個LUN 給iSCSI target
```shell
       # cd iqn.2024-12.com.edwin:target01/tpg1/luns
       # create /backstores/block/iscsi_disk01
```

### 6. 設定 portals
```shell
       # cd ..
       # cd portals/
       # delete 0.0.0.0 3260
       # create 192.168.20.21
       # create 192.168.20.22
```
### 7. 保存設定
```shell
       # cd /
       # saveconfig
       # exit
```
# #iSCSI client(initiator) 設定
## OS: ubuntu 22.04
### 1. 安裝所需套件
```shell
       # apt install open-iscsi       (預設應已安裝)
```
### 2. 設定iSCSI Initiator名稱
```shell
       # vi /etc/iscsi/initiatorname.iscsi
         InitiatorName=iqn.2024-12.com.edwin:initiator01
```
### 3. 設定CHAP 認證(如果有)
```shell
       # vi /etc/iscsi/iscsid.conf
         uncommont CHAP Settings
```
### 4. 重新啟動iscsi服務
```shell
       # systemctl restart iscsid.service open-iscsi.service
```
### 5. 發現iSCSI target
```shell
       # iscsiadm -m discovery -t sendtargets -p 192.168.20.21
```
### 6. 將iSCSI initiator加入iSCSI target ACLs
```shell
    === 從iSCSI target 設定
    # targetcli
    # cd iqn.2024-12.com.edwin:target01/tpg1/acls
    # create iqn.2024-12.com.edwin:initiator01
```
### 7. Login到iSCSI target
```shell
    # iscsiadm -m node --login -p 192.168.20.21
    # iscsiadm -m node --login -p 192.168.20.22
```
### 8. 設定自動連線
```shell
    # iscsiadm -m node -p 192.168.20.21 -o update -n node.startup -v automatic
    # iscsiadm -m node -p 192.168.20.22 -o update -n node.startup -v automatic
```
### 9. 確認連線
```shell
    # iscsiadm -m session -o show
```
### 10. 設定multipath
```shell
    # apt install multipath-tools     (預設應已安裝)
    # multipath -ll
    # lsblk
```
### 11. 格式化
```shell
    # mkfs.ext4 /dev/mapper/mpatha
```
### 12. 掛載multipath device
```shell
    # mkdir /mnt/iscsi01
    # mount /dev/mapper/mpatha /mnt/iscsi01
    # df -h
```
### 13. 更新 /etc/fatab
```shell
    # vi /etc/fstab
      === 設定為naauto, 防止自動掛載時, iscsi尚未起來

     /dev/mapper/mpatha /mnt/iscsi01 ext4 noauto,_netdev 0 2

     === 設定一個systemd mount檔 (注意: 檔名應與你的目錄位置相同)
    # vi /etc/systemd/system/mnt-iscsi01.mount

    [Unit]
    Description=Mount multipath device
    After=network-online.target iscsid.service open-iscsi.service
    Wants=network-online.target iscsid.service open-iscsi.service
    
    [Mount]
    What=/dev/mapper/mpatha
    Where=/mnt/iscsi01
    Type=ext4
    Options=_netdev
    
    [Install]
    WantedBy=multi-user.target

    # systemctl daemon-reload
    # systemctl enable mnt-iscsi01.mount
    # systemctl start mnt-iscsi01.mount
```
### 14. 重新開機測試
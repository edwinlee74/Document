# Persistent Volume 
PV是一種cluster resource, 由管理員事先配置的storage, 並透過PVC（PersistentVolumeClaim）由用戶端來請求這個storage。

# 建立一個PV
 * iscsi1-template.yaml
```shell
apiVersion: v1
kind: PersistentVolume
metadata:
  name: iscsi-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem      # or Block
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  iscsi:
     targetPortal: 10.16.154.81:3260
     iqn: iqn.2014-12.example.server:storage.target00
     lun: 0
     fsType: 'ext4'
```

 * iscsi2-template.yaml

   CHAP配置
```shell
apiVersion: v1
kind: PersistentVolume
metadata:
  name: iscsi-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  iscsi:
    targetPortal: 10.0.0.1:3260
    iqn: iqn.2016-04.test.com:storage.target00
    lun: 0
    fsType: ext4
    chapAuthDiscovery: true 
    chapAuthSession: true 
    secretRef:
      name: chap-secret 
```
 * iscsi3-template.yaml

   Multi Path配置
```shell
apiVersion: v1
kind: PersistentVolume
metadata:
  name: iscsi-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  iscsi:
    targetPortal: 10.0.0.1:3260
    portals: ['10.0.2.16:3260', '10.0.2.17:3260', '10.0.2.18:3260'] 
    iqn: iqn.2016-04.test.com:storage.target00
    lun: 0
    fsType: ext4
    readOnly: false
```

 * fc-template.yaml
   
```shell
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0001
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  fc:
    wwids: [scsi-3600508b400105e210000900000490000] 
    targetWWNs: ['500a0981891b8dc5', '500a0981991b8dc5'] 
    lun: 2 
    fsType: ext4
```

# 建立一個PVC

 * iscsi-pvc.yaml

```shell
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: iscsi-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  volumeMode: Filesystem  # 或 Block
  storageClassName: ""  # 如果使用靜態 PV，這裡要設為空
```
# 使用iSCSI PV的Pod

 * iscsi-pv-pod.yaml

```shell
apiVersion: v1
kind: Pod
metadata:
  name: iscsi-test-pod
spec:
  containers:
    - name: app
      image: busybox
      command: [ "sleep", "3600" ]
      volumeMounts:
        - mountPath: "/mnt/iscsi"
          name: iscsi-storage
  volumes:
    - name: iscsi-storage
      persistentVolumeClaim:
        claimName: iscsi-pvc
```
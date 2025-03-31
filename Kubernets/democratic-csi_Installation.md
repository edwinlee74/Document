# democratic-csi

參考:[github](https://github.com/democratic-csi/democratic-csi)

democratic-csi 是一種 csi (container storage interface)的實作, 該專案是針對zfs-based storage systems,

主要是FreeNAS / TrueNAS and ZoL on Ubuntu。

## 準備事項


##
```shell
csiDriver:
  name: "org.democratic-csi.nfs"

storageClasses:
  - name: truenas-nfs-csi
    defaultClass: true
    reclaimPolicy: Retain
    volumeBindingMode: Immediate
    allowVolumeExpansion: true
    parameters:
      fsType: nfs

    mountOptions:
      - noatime
      - nfsvers=4.2
    secrets:
      provisioner-secret:
      controller-publish-secret:
      node-stage-secret:
      node-publish-secret:
      controller-expand-secret:

# if your cluster supports snapshots you may enable below
volumeSnapshotClasses: []

driver:
  config:
    # please see the most up-to-date example of the corresponding config here:
    # https://github.com/democratic-csi/democratic-csi/tree/master/examples
    # YOU MUST COPY THE DATA HERE INLINE!
    driver: freenas-nfs
    instance_id:
    httpConnection:
      protocol: http
      host: <Put your TrueNAS FQDN or fixed IP here>
      port: 80
      apiKey: <Use the api key retrieved from the TrueNAS server>
      username: root
      allowInsecure: true
      apiVersion: 2
    sshConnection:
      host: <Put your TrueNAS FQDN or fixed IP here>
      port: 22
      username: root
      # use either password or key
      privateKey: |
        <Paste the ssh private key of your authorized server here>
    zfs:
      datasetParentName: <Use the dataset name you created on the storage server, ie: hdd/nfs>
      detachedSnapshotsDatasetParentName: <Use the dataset name you created on the storage serverie: hdd/snapshots>
      datasetEnableQuotas: true
      datasetEnableReservation: false
      datasetPermissionsMode: "0777"
      datasetPermissionsUser: 0
      datasetPermissionsGroup: 0
    nfs:
      shareHost: <Put your TrueNAS FQDN or fixed IP here>
      shareAlldirs: false
      shareAllowedHosts: []
      shareAllowedNetworks: []
      shareMaprootUser: root
      shareMaprootGroup: wheel
      shareMapallUser: ""
      shareMapallGroup: ""
```
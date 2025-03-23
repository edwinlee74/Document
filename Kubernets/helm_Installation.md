# Helm 安裝

官網： https://helm.sh/

Helm是Kubernetes的套件管理器，chart則為該套件格式。


## Helm Version Support Policy

Helm的版本以x.y.z方式描述，x為主版本，y為次要版本，z則為patch版本，遵循Semantic Versioning。

從helm3開始， 會與kubernetes保持n-3版本的相容， 例如： helm版本為3.12.x, 則對應kubernetes的

相容版本為1.27.x - 1.24.x。

## 安裝方式
 
* Binary 方式安裝

  1. 直接從github下載: https://github.com/helm/helm/releases
  2. 直接解壓縮 （tar -zxvf helm-v3.0.0-linux-amd64.tar.gz）
  3. 移動到所要目錄位置（mv linux-amd64/helm /usr/local/bin/helm）

* Script 方式安裝

  ```shell
  $ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  $ chmod 700 get_helm.sh
  $ ./get_helm.sh
  ```
## 安裝後檢查

註： RKE2基本上已有helm [HelmChart resource definition](https://github.com/k3s-io/helm-controller#helm-controller)，
    但沒有helm command line tool, 需要另外安裝。

```shell
edwin@rke-master3:~$ helm ls -A

NAME                            	NAMESPACE  	REVISION	UPDATED                                	STATUS  	CHART                                   	APP VERSION
rke2-canal                      	kube-system	1       	2025-03-21 02:24:23.674892944 +0000 UTC	deployed	rke2-canal-v3.29.1-build2024121100      	v3.29.1    
rke2-coredns                    	kube-system	1       	2025-03-21 02:24:23.769011087 +0000 UTC	deployed	rke2-coredns-1.36.102                   	1.11.3     
rke2-ingress-nginx              	kube-system	1       	2025-03-21 02:27:35.369892933 +0000 UTC	deployed	rke2-ingress-nginx-4.10.503             	1.10.5     
rke2-metrics-server             	kube-system	1       	2025-03-21 02:27:35.40492442 +0000 UTC 	deployed	rke2-metrics-server-3.12.004            	0.7.1      
rke2-snapshot-controller        	kube-system	1       	2025-03-21 02:28:17.39595413 +0000 UTC 	deployed	rke2-snapshot-controller-3.0.601        	v8.1.0     
rke2-snapshot-controller-crd    	kube-system	1       	2025-03-21 02:27:35.340150294 +0000 UTC	deployed	rke2-snapshot-controller-crd-3.0.601    	v8.1.0     
rke2-snapshot-validation-webhook	kube-system	1       	2025-03-21 02:27:31.506049379 +0000 UTC	deployed	rke2-snapshot-validation-webhook-1.9.001	v8.1.0     
```

# 新增一個repo

```shell
### 將一個chart倉庫url加入
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories

### 查看該倉庫的chart 列表
$ helm search repo bitnami

NAME                                        	CHART VERSION	APP VERSION  	DESCRIPTION                                       
bitnami/airflow                             	22.7.0       	2.10.5       	Apache Airflow is a tool to express and execute...
bitnami/apache                              	11.3.4       	2.4.63       	Apache HTTP Server is an open-source HTTP serve...
bitnami/apisix                              	4.2.0        	3.11.0       	Apache APISIX is high-performance, real-time AP...
bitnami/appsmith                            	5.2.2        	1.64.0       	Appsmith is an open source platform for buildin...
bitnami/argo-cd                             	7.3.0        	2.14.7       	Argo CD is a continuous delivery tool for Kuber...
bitnami/argo-workflows                      	11.1.10      	3.6.5        	Argo Workflows is meant to orchestrate Kubernet...
bitnami/aspnet-core                         	6.3.5        	8.0.14       	ASP.NET Core is an open-source framework for we...
bitnami/cassandra                           	12.2.2       	5.0.3        	Apache Cassandra is an open source distributed ...
```
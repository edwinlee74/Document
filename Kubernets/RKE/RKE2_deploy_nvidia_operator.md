# Deploy NVIDIA operator

### 安裝之前需先安裝nvidia driver。

```shell
/* 查看driver及CUDA版本 */

# nvidia-smi
Mon Mar 31 15:33:57 2025       
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.120                Driver Version: 550.120        CUDA Version: 12.4     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce 940MX           Off |   00000000:02:00.0 Off |                  N/A |
| N/A   40C    P8             N/A /  200W |      29MiB /   2048MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
                                                                                         
+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A      4042      G   /usr/lib/xorg/Xorg                              2MiB |
|    0   N/A  N/A      4320    C+G   ...libexec/gnome-remote-desktop-daemon         20MiB |
+-----------------------------------------------------------------------------------------+
```
### 新增 NVIDIA Helm 儲存庫
```shell
$ helm repo add nvidia https://helm.ngc.nvidia.com/nvidia && helm repo update
```
### 安裝gpu operator
*注意: 安裝時會重啟containerd及RKE2*

```shell
 $ helm install --wait --generate-name \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator \
    --version=v25.3.0 \
    --set driver.enabled=false \
    --set toolkit.env[0].name=CONTAINERD_CONFIG \
    --set toolkit.env[0].value=/var/lib/rancher/rke2/agent/etc/containerd/config.toml \
    --set toolkit.env[1].name=CONTAINERD_SOCKET \
    --set toolkit.env[1].value=/run/k3s/containerd/containerd.sock \
    --set toolkit.env[2].name=CONTAINERD_RUNTIME_CLASS \
    --set toolkit.env[2].value=nvidia \
    --set toolkit.env[3].name=CONTAINERD_SET_AS_DEFAULT \
    --set-string toolkit.env[3].value=true
    
```

### 檢查該GPU node是否已偵測到GPU及driver

```shell
 $ kubectl get node $NODENAME -o jsonpath='{.metadata.labels}' | jq | grep "nvidia.com"
   "nvidia.com/cuda.driver-version.full": "550.120",
   "nvidia.com/cuda.driver-version.major": "550",
   "nvidia.com/cuda.driver-version.minor": "120",
   "nvidia.com/cuda.driver-version.revision": "",
   "nvidia.com/cuda.driver.major": "550",
   "nvidia.com/cuda.driver.minor": "120",
   "nvidia.com/cuda.driver.rev": "",
   "nvidia.com/cuda.runtime-version.full": "12.4",
   "nvidia.com/cuda.runtime-version.major": "12",
   "nvidia.com/cuda.runtime-version.minor": "4",
   "nvidia.com/cuda.runtime.major": "12",
   "nvidia.com/cuda.runtime.minor": "4",
   "nvidia.com/gfd.timestamp": "1743408700",
   "nvidia.com/gpu.compute.major": "5",
   "nvidia.com/gpu.compute.minor": "0",
   ............................................
   ............................................
   ............................................(省略)
```

### 檢查container runtime binary已被operator安裝

```shell
/* 在GPU node上檢查 */
$ ls /usr/local/nvidia/toolkit/nvidia-container-runtime
```

### 檢查containerd config 已被更新

```shell
# grep nvidia /var/lib/rancher/rke2/agent/etc/containerd/config.toml
plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia"]
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia".options]
  BinaryName = "/usr/local/nvidia/toolkit/nvidia-container-runtime"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia-cdi"]
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes."nvidia-cdi".options]
  BinaryName = "/usr/local/nvidia/toolkit/nvidia-container-runtime.cdi"
```

### 建立一個Pod來測試GPU

```shell
kubectl apply -f -<<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nbody-gpu-benchmark
  namespace: default
spec:
  restartPolicy: OnFailure
  runtimeClassName: nvidia
  containers:
  - name: cuda-container
    image: nvcr.io/nvidia/k8s/cuda-sample:nbody
    args: ["nbody", "-gpu", "-benchmark"]
    resources:
      limits:
        nvidia.com/gpu: 1
    env:
    - name: NVIDIA_VISIBLE_DEVICES
      value: all
    - name: NVIDIA_DRIVER_CAPABILITIES
      value: all
EOF
```

### 檢查 pod 運行的日誌:

```shell
$ kubectl logs pod/nbody-gpu-benchmark
Run "nbody -benchmark [-numbodies=<numBodies>]" to measure performance.
	-fullscreen       (run n-body simulation in fullscreen mode)
	-fp64             (use double precision floating point values for simulation)
	-hostmem          (stores simulation data in host memory)
	-benchmark        (run benchmark to measure performance) 
	-numbodies=<N>    (number of bodies (>= 1) to run in simulation) 
	-device=<d>       (where d=0,1,2.... for the CUDA device to use)
	-numdevices=<i>   (where i=(number of CUDA devices > 0) to use for simulation)
	-compare          (compares simulation results running once on the default GPU and once on the CPU)
	-cpu              (run n-body simulation on the CPU)
	-tipsy=<file.bin> (load a tipsy model file for simulation)

NOTE: The CUDA Samples are not meant for performance measurements. Results may vary when GPU Boost is enabled.

> Windowed mode
> Simulation data stored in video memory
> Single precision floating point simulation
> 1 Devices used for simulation
GPU Device 0: "Maxwell" with compute capability 5.0

> Compute 5.0 CUDA device: [NVIDIA GeForce 940MX]
3072 bodies, total time for 10 iterations: 3.641 ms
= 25.917 billion interactions per second
= 518.344 single-precision GFLOP/s at 20 flops per interaction
```

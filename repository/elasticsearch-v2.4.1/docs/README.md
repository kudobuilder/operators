# 使用定义的elasticsearch镜像构建es集群
镜像为ruguodangshi/elasticsearch-unicom:2.4.1
### 前提
- 在k8s集群创建名为local-storage的storageClass
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage 
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```
- 集群中有足够的空闲的pv，数量大于等于nodeNum，pv示例
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-test-zk01 
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain  
  storageClassName: local-storage
  local:
    path: /data/k8sLocalPv/tests-zk01
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: volume 
          operator: In
          values:
          - test-zk01
```

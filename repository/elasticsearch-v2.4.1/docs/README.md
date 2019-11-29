# elasticsearch-v2.4.1
Elasticsearch is an open source distributed search engine ，it is Large-scale used in China Unicom.
Since our production environment has always used the 2.x version of es, and a lot of parameter optimizations have been done on this version, we have built this es operator on the basis of version 2.4.1.
The image used in the operator has been passed to my own dockerhub repository，tag is "ruguodangshi/elasticsearch-unicom:2.4.1".
You can run ```docker pull ruguodangshi/elasticsearch-unicom:2.4.1``` to get it.
### Prerequisite
- create a storageClass in your k8s cluster
The yaml is like blow：
 ```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage 
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```
- Create pv using the storageClass from the previous step
The number of pv must be equal to nodeNum
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

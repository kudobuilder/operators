

# Limitations

Below is a list of parameters that can only be configured during bootstrap time.

|Immutable Parameters|
| ------------------ |
| DISK_SIZE          | 
| STORAGE_CLASS      |

These storage-related parameters cannot be changed after initial deployment. Repeat: using parameters to resize disk, change storage class, or switch between persistent/ephemeral storage is not supported.

Changing the above parameters will trigger a `not-allowed` plan. Which basically skips updating any resources.
This is to avoid any update done by mistake or human error. 

### Resizing the PVC 

Resizing the disk depends on the storage class of your Kubernetes cluster.
To resize the disk being used by zookeeper, users can edit the `pvc` and expand the disk.
You can read more about it in [resizing the PVC](https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/) post.

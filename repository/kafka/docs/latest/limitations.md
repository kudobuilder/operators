

# Limitations

Below is a list of parameters that can only be configured during bootstrap time:

**DISK_SIZE**, **STORAGE_CLASS** and **PERSISTENT_STORAGE** 

These storage-related parameters cannot be changed after initial deployment. Repeat: using parameters to resize disk, change storage class, or switch between persistent/ephemeral storage is not supported.

### Resizing the PVC 

Resizing the disk depends on the storage class of your Kubernetes cluster.
To resize the disk being used by a broker, users can edit the `pvc` and expand the disk.

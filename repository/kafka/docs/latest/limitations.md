

# Limitations



Below is the list of parameters that can only be configured during bootstrap time.

**DISK_SIZE**, **STORAGE_CLASS** and **PERSISTENT_STORAGE** 

These next storage related parameters cannot be changed. Resizing disk, changing storage class or switching between pesistent storage or ephemeral using parameters isn't supported.



### Resizing the PVC 

Resizing the disk depends on the storage class of the Kubernetes.



To resize the disk being used by a broker. Users can edit the `pvc` and expand the disk 
# Configuration 

### Resources

By default, KUDO Zookeeper resource configuration is set to the minimum recommended values for production usage. 
But users can and should tune the configurations based on the workload requirements of their Kafka cluster.  

##### Tuning the resources for the Zookeeper Cluster

```
kubectl kudo install zookeeper --instance=my-zookeeper-name \
            -p CPUS=1 \
            -p NODE_COUNT=5 \
            -p MEMORY=1Gi \
            -p DISK_SIZE=5Gi \
```
The parameter `CLIENT_PORT`(default: 2181) sets the port for listening to client requests. Similarly, `SERVER_PORT`(default: 2888) is used to set port on which zookeeper will listen for requests from other servers in the ensemble and `ELECTION_PORT`(default: 3888) can be used to set the port on which the Zookeeper process will perform leader election.


##### Storage

By default, the Zookeeper operator will use the default storage class of the Kubernetes cluster. 

To deploy Kafka using a different storage class, you can use the parameter `STORAGE_CLASS`

```
kubectl kudo install zookeeper --instance=my-zookeeper-name -p STORAGE_CLASS=<STORAGE_CLASS_NAME>
```

##### Docker image

The Dockerfile used to build the KUDO Zookeeper operator is hosted at [Zookeeper's Dockerhub Repository](https://hub.docker.com/_/zookeeper).

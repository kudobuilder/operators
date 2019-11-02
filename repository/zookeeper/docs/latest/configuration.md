# Configuration 

### Resources

By default, KUDO Zookeeper resource configuration is set to the minimum recommended values for production usage. 
But users can and should tune the configurations based on the workload requirements of whatever service makes use of Zookeeper.

##### Tuning the resources for the Zookeeper Cluster

```
kubectl kudo install zookeeper --instance=my-zookeeper-name \
            -p CPUS=1 \
            -p NODE_COUNT=5 \
            -p MEMORY=1Gi \
            -p DISK_SIZE=5Gi \
```

##### Ports

The parameter `CLIENT_PORT`(default: 2181) sets the port for listening to client requests.
Similarly, `SERVER_PORT`(default: 2888) is used to set the port which zookeeper will listen on for requests from other servers in the ensemble and `ELECTION_PORT`(default: 3888) can be used to set the port on which the Zookeeper process will perform leader election.


##### Storage

By default, the Zookeeper operator will use the default storage class of the Kubernetes cluster. 

To deploy Zookeeper using a different storage class, you can use the parameter `STORAGE_CLASS`

```
kubectl kudo install zookeeper --instance=my-zookeeper-name -p STORAGE_CLASS=<STORAGE_CLASS_NAME>
```

##### Docker image

The Dockerfile used to build the KUDO Zookeeper operator is hosted [here](https://github.com/31z4/zookeeper-docker/blob/5a82d0b90d055f39d50e0a64ae2e00da15f9b8b1/3.4.14/Dockerfile). For more details, please check [Zookeeper's Dockerhub Repository](https://hub.docker.com/_/zookeeper).

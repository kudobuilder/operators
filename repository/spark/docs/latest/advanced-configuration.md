Advanced configuration options
---

## Using Volcano as a Batch Scheduler

Volcano is a batch system built on Kubernetes. It provides a suite of mechanisms that are commonly required by many classes of batch & elastic workload including distributed data processing and machine learning. Spark Operator can be integrated with Volcano to get more efficient pod scheduling as well as fine-grained control of Spark applications scheduling via queues and priority classes. To get more information about the Volcano system and how to install it on your K8s cluster, visit [https://volcano.sh/](https://volcano.sh/).

To enable batch scheduler, install Spark Operator with the following parameter:

```bash
$ kubectl kudo install spark \
    --namespace=spark-operator \
    -p enableBatchScheduler=true
```
In `SparkApplication` yaml file, add the following parameter to the `spec` section:
```
batchScheduler: "volcano"
```
After the application is submitted, verify the driver pod is scheduled by Volcano:

```bash
$ kubectl describe spark-pi-driver -n spark-operator
...
Events:
  Type     Reason       Age   From               Message
  ----     ------       ----  ----               -------
  Normal   Scheduled    76s   volcano            Successfully assigned spark-operator/spark-pi-driver to <node-name>
...
```

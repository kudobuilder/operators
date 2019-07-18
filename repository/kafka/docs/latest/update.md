

# Update the Kafka cluster

#### Tuning the configuration 

Check the limitations to see which parameters can only be set during bootstrap time. 



## Scaling the brokers

For the stateful workload it is not recommended to configure the HPA or VPA for Kafka brokers. 

More controlled scaling is more conveninent considering the nature of stateful workload.  

#### Horizontally 

To scale horizontally we need to scale our brokers count from default 3 to 5. 

When checking the kafka instance we can see any custom parameters present in the instance. In this case we only see 1 custom parameter that is `ZOOKEEPER_URI`

```
> kubectl describe instances -l operator=kafka
Name:         kafka
Namespace:    default
Labels:       controller-tools.k8s.io=1.0
              operator=kafka
Annotations:  <none>
API Version:  kudo.k8s.io/v1alpha1
Kind:         Instance
Metadata:
  Creation Timestamp:  2019-07-17T15:57:09Z
  Generation:          10
  Resource Version:    227951
  Self Link:           /apis/kudo.k8s.io/v1alpha1/namespaces/default/instances/kafka
  UID:                 a13d648a-2d58-4672-9be7-63ecf2db55b6
Spec:
  Operator Version:
    Name:  kafka-0.1.1
  Parameters:
    ZOOKEEPER_URI:  zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181
Status:
  Active Plan:
    API Version:  kudo.k8s.io/v1alpha1
    Kind:         PlanExecution
    Name:         kafka-deploy-351387000
    Namespace:    default
    UID:          d34d38e7-1940-4670-83a3-56b486bccff4
  Status:         COMPLETE
Events:
  Type    Reason               Age                 From                      Message
  ----    ------               ----                ----                      -------
  Normal  CreatePlanExecution  5m3s (x2 over 20h)  instance-controller       Creating "deploy" plan execution
  Normal  PlanCreated          5m3s                instance-controller       PlanExecution "kafka-deploy-351387000" created
  Normal  PlanComplete         3m56s               planexecution-controller  PlanExecution kafka-deploy-351387000 completed
```

Lets update the broker count from default `3` to `5`

```
> kubectl patch instance kafka -p '{"spec":{"parameters":{"BROKER_COUNT":"5"}}}' --type=merge
instance.kudo.k8s.io/kafka patched
```

Check the plan status:

```
> kubectl kudo plan status --instance=kafka
Plan(s) for "kafka" in namespace "default":
.
└── kafka (Operator-Version: "kafka-0.2.0" Active-Plan: "kafka-deploy-351387000")
    └── Plan deploy (serial strategy) [IN_PROGRESS]
        └── Phase deploy-kafka (serial strategy) [IN_PROGRESS]
            └── Step deploy (IN_PROGRESS)
```

Once the plan status is complete

```kubectl kudo plan status --instance=kafka
> kubectl kudo plan status --instance=kafka
Plan(s) for "kafka" in namespace "default":
.
└── kafka (Operator-Version: "kafka-0.2.0" Active-Plan: "kafka-deploy-351387000")
    └── Plan deploy (serial strategy) [COMPLETE]
        └── Phase deploy-kafka (serial strategy) [COMPLETE]
            └── Step deploy (COMPLETE)
```

We can see that we have 5 brokers up and running

```
> kubectl get pods -l app=kafka
NAME            READY   STATUS    RESTARTS   AGE
kafka-kafka-0   1/1     Running   0          7m26s
kafka-kafka-1   1/1     Running   0          8m26s
kafka-kafka-2   1/1     Running   0          8m53s
kafka-kafka-3   1/1     Running   0          10m
kafka-kafka-4   1/1     Running   0          9m21s
```



**Vertically** 

To scale vertically the brokers statefulset pods we can use the parameters also.

```
> kubectl describe statefulset kafka-kafka
[ ... lines removed for clarity ...]
    Requests:
      cpu:      500m
      memory:   2048m
[ ... lines removed for clarity ...]
```



Lets change the cpu request from `500m` to `700m` and double the memory request from `2048` to `4096` and not forget the limits, that cannot be lower than the requested resources. 

```
kubectl patch instance kafka -p '{"spec":{"parameters":{"BROKER_CPUS":"700m", "BROKER_MEM":"4096m", "BROKER_CPUS_LIMIT":"3000m", "BROKER_MEM_LIMIT":"6144"}}}' --type=merge
```

Now we will see a rolling upgrade of the pods towards 

```
> kubectl describe statefulset kafka-kafka
[ ... lines removed for clarity ...]
    Requests:
      cpu:      700m
      memory:   4096m
[ ... lines removed for clarity ...]
```




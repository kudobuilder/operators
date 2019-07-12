



Install the new operator version
```
kubectl kudo install kafka --version=0.2.0 --skip-instance

operator.kudo.k8s.io/kafka unchanged
operatorversion.kudo.k8s.io/v1alpha1/kafka-0.2.0 created
```


```
kubectl  get operatorversions.kudo.k8s.io

NAME              AGE
kafka-0.1.1       2d2h
kafka-0.2.0       2m6s
```

Now we have two operator versions installed. 

```
kubectl get instances
NAME           AGE
kafka-fc6vzn   29h
```

And we can check the plan status of our Kafka cluster `kafka-fc6vzn`  
```
kubectl kudo plan status --instance=kafka-fc6vzn
Plan(s) for "kafka-fc6vzn" in namespace "default":
.
└── kafka-fc6vzn (Operator-Version: "kafka-0.1.1" Active-Plan: "kafka-fc6vzn-deploy-414458000")
    └── Plan deploy (serial strategy) [COMPLETE]
        └── Phase deploy-kafka (serial strategy) [COMPLETE]
            └── Step deploy (COMPLETE)
```
Note the operator version `kafka-0.1.1`

Lets update the Kafka cluster from version 0.1.1 to 0.2.0

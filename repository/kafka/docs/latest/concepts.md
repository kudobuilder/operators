![kudo-kafka](./resources/images/kudo-kafka.png)

# KUDO Kafka Concepts

KUDO Kafka is a Kubernetes operator build on top of [KUDO](kudo.dev) and requires KUDO

#### KUDO Kafka CRDs

There are three CRDs, that are installed for KUDO Kafka.

- Operator
- OperatorVersion
- Instance

An Instance represents an instantiation of a KUDO Kafka cluster. The Operator and OperatorVersion hold all knowledge to instantiate the KUDO Kafka cluster. 

#### KUDO Controller Reconcile Cycle

KUDO controller watches the CRDs of Operator, OperatorVersion and Instance in Kubernetes API

![kudo-kafka](./resources/images/kudo-controller-kafka.png)

When the user install the KUDO Kafka using kudo-cli, it creates the KUDO Kafka CRDs for Operator, OperatorVersion and Instance. More informration can be read in [KUDO Architecture](https://kudo.dev/docs/architecture.html#architecture-diagram) 

![kudo-kafka](./resources/images/kudo-installs-kafka.png)

When KUDO Controller detects a new `Instance` it creates all the resources required to reach the desired state of the configuration. 

![kudo-kafka](./resources/images/kafka-cluster.png)

Same process is followed for any updates and deletion that is handled by the KUDO Controller.

![kudo-kafka](./resources/images/kudo-update-kafka.png)


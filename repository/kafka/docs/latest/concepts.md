![kudo-kafka](./resources/images/kudo-kafka.png)

# KUDO Kafka Concepts

KUDO Kafka is a Kubernetes operator built on top of [KUDO](kudo.dev) and requires KUDO

#### KUDO Kafka CRDs

There are three CRDs that are installed when deploying KUDO Kafka:

- Operator: the definition that describes the Kudo Kafka operator.
- OperatorVersion: the definition that describes the Kudo Kafka operator for a specific version.
- Instance: the instantiation of a KUDO Kafka cluster based on the OperatorVersion.

#### KUDO Controller Reconcile Cycle

The KUDO controller continually watches the Operator, OperatorVersion and Instance CRDs via the Kubernetes API.

![kudo-kafka](./resources/images/kudo-controller-kafka.png)

When a user installs KUDO Kafka using the `kudo-cli`, the controller creates the KUDO Kafka CRDs for Operator, OperatorVersion and Instance. More information can be read in [KUDO Architecture](https://kudo.dev/docs/architecture.html#architecture-diagram) 

![kudo-kafka](./resources/images/kudo-installs-kafka.png)

When the KUDO Controller detects a new `Instance`, it creates all the resources required to reach the desired state of the configuration. 

![kudo-kafka](./resources/images/kafka-cluster.png)

The same process is followed for any updates or deletions. Everything is handled by the KUDO Controller.

![kudo-kafka](./resources/images/kudo-update-kafka.png)


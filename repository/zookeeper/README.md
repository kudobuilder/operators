# Zookeeper Operator

The KUDO Zookeeper operator creates, configures and manages [Apache Zookeeper](https://zookeeper.apache.org/) clusters running on Kubernetes.

## Getting started

The latest stable version of Zookeeper operator is `0.3.4`

## Version Chart

| KUDO Zookeeper Version | Apache Zookeeper Version |
| ---------------------- | ------------------------ |
| 0.3.4                  | 3.6.2                    |
| 0.3.3                  | 3.6.2                    |
| 0.3.2                  | 3.4.14                   |
| 0.3.1                  | 3.4.14                   |
| 0.3.0                  | 3.4.14                   |
| latest                 | 3.6.2                    |

## Custom Zookeeper Versions

The operator contains a parameter `IMAGE_VERSION` with a default that is the current zookeeper version, normally something like `zookeeper:3.6.2`. You can change this parameter to a different image, but the operator may not run correctly, as there may be missing configuration or other changes to the default version.

Additionally, if you specify the `IMAGE_VERSION` manually, you will not get an updated zookeeper version if you update the operator - in this case you will need to update the `IMAGE_VERSION` yourself on an operator update.
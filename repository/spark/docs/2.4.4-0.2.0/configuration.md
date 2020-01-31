KUDO Spark Operator Configuration
---

## Default configuration
The default KUDO Spark configuration enables installation of the following resources:
* CRDs (Custom Resource Definitions) for `SparkApplication` and `ScheduledSparkApplication`
* Service Account, `ClusterRole`, and `ClusterRoleBinding` for Operator
* Service Account, `Role`, and `RoleBinding` for Spark Applications (Drivers)
* Spark Operator Controller which handles submissions and launches Spark Applications
* Mutating Admission Webhook for customizing Spark driver and executor pods based on the specification
* `MetricsService` for Spark Operator and Spark Applications to enable metrics scraping by Prometheus

Full list of configuration parameters and defaults is available in KUDO Spark [params.yaml](../../operator/params.yaml).
## Docker
Docker images used by KUDO Spark and image pull policy can be specified by providing the following parameters:
```bash
kubectl kudo install spark --instance=spark-operator \
        -p operatorImageName=mesosphere/kudo-spark-operator \
        -p operatorVersion=latest \
        -p imagePullPolicy=Always
```

## Monitoring
Metrics reporting is disabled by default and can be enabled by providing `-p enableMetrics=true` parameter:
```bash
kubectl kudo install spark --instance=spark-operator -p enableMetrics=true
```
When enabled, KUDO Spark installs Metrics Services and Service Monitors to enable metrics scraping by Prometheus. More
information about how KUDO Spark exposes metrics and metrics configuration  is available in [KUDO Spark Operator Monitoring](monitoring.md)
documentation.

## Spark History Server
KUDO Spark comes bundled with Spark History Server which is disabled by default. It can be enabled via `-p enableHistoryServer=true`:
```bash
kubectl kudo install spark --instance=spark-operator -p enableHistoryServer=true
```

More information about Spark History Server configuration is available in [Spark History Server Configuration](history-server.md)
documentation.

## Service Accounts and RBAC
By default, KUDO Spark will create service accounts, roles, and role bindings with preconfigured permissions required
for running Spark Operator and submitting Spark Applications.

### Service Accounts
The following parameters configure service account settings for Spark Operator:
```bash
kubectl kudo install spark --instance=spark-operator \
        -p operatorServiceAccountName=<service account name> \
        -p createOperatorServiceAccount=<true|false>
```
To use existing service account for the Operator, `createOperatorServiceAccount` parameter should be set to `false`.

Service account configuration for Spark Applications follows the same pattern:
```bash
kubectl kudo install spark --instance=spark-operator \
        -p sparkServiceAccountName=<service account name> \
        -p createSparkServiceAccount=<true|false>
```
To use existing service account for Spark, `createSparkServiceAccount` parameter should be set to `false`.

### RBAC
KUDO Spark `ClusterRole` with necessary permissions created automatically, but this can be disabled by providing `-p createRBAC=false` parameter:
```bash
kubectl kudo install spark --instance=spark-operator -p createRBAC=<true|false>
```

KUDO Spark requires a `ClusterRole` to be configured in order for it to handle custom resources, listen to events, work
with secrets, configmaps, and services. The full list of permissions is available in [spark-operator-rbac.yaml](../../operator/templates/spark-operator-rbac.yaml).
If `createRBAC` parameter is set to `false`, a `ClusterRole` and `ClusterRoleBinding` should be created or exist before 
the installation. `ClusterRoleBinding` should be linked to the Service Account used by the Operator. 

Spark Applications submitted to KUDO Spark also require permissions to launch Spark Executors and monitor their state. For this
purpose KUDO Spark creates a `Role` for them and binds it to a service account provided via `-p sparkServiceAccountName=<service account name>`.
If `createRBAC` flag is set to `false`, a `Role` (with a `RoleBinding` linked to Spark Service Account) should be
created or exist prior to submission of Spark Applications. `Role` configuration and a list of required permissions are
available in [spark-rbac.yaml](../../operator/templates/spark-rbac.yaml) template file.

# Cruise Control

## Overview

KUDO Kafka operator comes with builtin integration of [Cruise Control](https://github.com/linkedin/cruise-control).

Cruise Control is a tool to fully automate the dynamic workload rebalance and self-healing of a kafka cluster. It provides great value to Kafka users by simplifying the operation of Kafka clusters.

Cruise Control integration is disabled by default.

## Setup Cruise Control

### Start Cruise Control

Update the instance with `ENABLE_CRUISE_CONTROL` set to start Cruise Control alongside the KUDO Kafka instance.

```bash
$ kubectl kudo update --instance=kafka \
  -p ENABLE_CRUISE_CONTROL=true
```
## Advanced Options

|Parameter|Description|Example|
|--|--|--|
| CRUISE_CONTROL_PORT | Port for the Cruise Control server to listen to | <ul><li> 9090 (default) </li></ul> |
| CRUISE_CONTROL_WEBSERVER_API_URLPREFIX | Cruise Control REST API default prefix | <ul><li>"/kafkacruisecontrol/*" (default)</li></ul> |
| CRUISE_CONTROL_WEBSERVER_UI_URLPREFIX | Cruise Control REST Web UI default path prefix | <ul><li>"/*" (default)</li></ul> |

## Disable Cruise Control

To disable Cruise Control, update the
instance with `ENABLE_CRUISE_CONTROL` set to `false`, using the following command:

```bash
$ kubectl kudo update --instance=kafka \
  -p ENABLE_CRUISE_CONTROL=false
``` 

## Limitations

Currently Cruise Control works with Kafka protocol `PLAINTEXT` only. It will not work if Kerberos and or TLS is
enabled in the Kafka instance. Future releases of KUDO Kafka will
address this limitation through a Cruise Control operator.

# KUDO DRUID #

## CREATE YOUR FIRST OPERATOR #

```
# Install kubectl-kudo cli
$ brew tap kudobuilder/tap
$ brew install kudo-cli

# Install Kudo Operator on Kubernetes
$ kubectl kudo init

# Build your Kudo Druid Operator
$ cd ~/SymbioTekGit/operators
$ chmod u+x ./build-operator.sh
$ ./build-operator.sh druid
Using KUDO Version: version.Info{GitVersion:"0.17.1", GitCommit:"f7fa1438", BuildDate:"2020-10-19T14:05:17Z", GoVersion:"go1.15.3", Compiler:"gc", Platform:"darwin/amd64", KubernetesClientVersion:"v0.19.2"}
package is valid
Package created: /Users/aheib/SymbioTekGit/operators/build/repo/druid-0.20.0_0.1.0.tgz

# Install your Druid Operator
$ kubectl kudo install ./build/repo/druid-0.20.0_0.1.0.tgz
operator default/druid created
operatorversion default/druid-0.20.0-0.1.0 created
instance default/druid-instance created
```

## RELEASES ##

* 0.1.0: First working KUDO Druid Operator, bootstraping a dummy ConfigMap



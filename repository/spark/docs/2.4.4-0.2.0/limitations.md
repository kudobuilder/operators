Limitations
---

## Multi-instance installation
* Currently, multi-instance (multi-tenant) operator installation supports only a single instance per namespace to
allow Spark applications be launched in the namespace they've been submitted to. Multiple operator instances
installed in the same namespace run job submissions in parallel which can potentially lead to race conditions
and inconsistent application state.
* Operator instances must have unique names to avoid clashes when `createRBAC` property is set to `true`.
KUDO Controller will reject new instance installation because it will try to create a `ClusterRole` with the same name.

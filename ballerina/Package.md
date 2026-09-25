## Overview

The Prometheus Observability Extension provides an implementation for exporting metrics to a [Prometheus](https://prometheus.io/) Server.

### Key Features

- Export application metrics to a Prometheus Server
- Configurable host and port for the metrics endpoint
- Simple configuration via import and Config.toml
- Seamless integration with observability tooling

### Enabling Prometheus Extension

To package the Prometheus extension into the Jar, follow the following steps.
1. Add the following import to your program.
```ballerina
import ballerinax/prometheus as _;
```

2. Add the following to the `Ballerina.toml` when building your program.
```toml
[package]
org = "my_org"
name = "my_package"
version = "1.0.0"

[build-options]
observabilityIncluded=true
```

To enable the extension and export metrics to Prometheus, add the following to the `Config.toml` when running your program.
```toml
[ballerina.observe]
metricsEnabled=true
metricsReporter="prometheus"

[ballerinax.prometheus]
host="127.0.0.1"  # Optional Configuration. Default value is localhost
port=9797         # Optional Configuration. Default value is 9797
```

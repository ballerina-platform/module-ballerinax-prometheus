# Ballerina Prometheus Observability Extension

[![Build](https://github.com/ballerina-platform/module-ballerinax-prometheus/workflows/Daily%20Build/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-prometheus/actions?query=workflow%3A"Daily+Build")
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-prometheus.svg)](https://github.com/ballerina-platform/module-ballerinax-prometheus/commits/main)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

The Prometheus Observability Extension is one of the metrics extensions of the <a target="_blank" href="https://ballerina.io/">Ballerina</a> language.

It provides an implementation for exporting metrics to a Prometheus Server.

## Enabling Prometheus Extension

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

## Building from the Source

### Setting Up the Prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).

    * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)

    * [OpenJDK](https://adoptopenjdk.net/)

      > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

### Building the Source

Execute the commands below to build from source.

1. To build the library:

        ./gradlew clean build

2. To run the integration tests:

        ./gradlew clean test

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss about code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
* View the [Ballerina performance test results](https://github.com/ballerina-platform/ballerina-lang/blob/master/performance/benchmarks/summary.md).

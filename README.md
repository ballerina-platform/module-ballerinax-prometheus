# Ballerina Prometheus Observability Extension

[![Build](https://github.com/ballerina-platform/module-ballerinax-prometheus/workflows/Daily%20Build/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-prometheus/actions?query=workflow%3A"Daily+Build")
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-prometheus.svg)](https://github.com/ballerina-platform/module-ballerinax-prometheus/commits/main)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![codecov](https://codecov.io/gh/ballerina-platform/module-ballerinax-prometheus/branch/main/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerinax-prometheus)

## Building from the Source

### Setting Up the Prerequisites

1. Download and install Java SE Development Kit (JDK) version 17 (from one of the following locations).

    * [Oracle](https://www.oracle.com/java/technologies/downloads/)

    * [OpenJDK](https://adoptopenjdk.net/)

      > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

### Building the Source

Execute the commands below to build from source.

1. To build the library:

        ./gradlew clean build

2. To run the integration tests:

        ./gradlew clean test

## Available Metrics

The exporter provides the following metrics.

|Metric Name|Description|
|---|---|
|response_time_seconds_value|Response time of a request in seconds|
|response_time_seconds_max|Maximum response time of a request|
|response_time_seconds_min|Minimum response time of a request|
|response_time_seconds_mean|Average response time of a request|
|response_time_seconds_stdDev|Standard deviation of response time of a request|
|response_time_seconds|Summary of request-response times across various time frames and quantiles|
|response_time_nanoseconds_total_value|Total response time for all requests|
|requests_total_value|Total number of requests|
|response_errors_total_value|Total number of response errors|
|inprogress_requests_value|Total number of inprogress requests|
|kafka_publishers_value|Number of publishers in kafka|
|kafka_consumers_value|Number of consumers in kafka|
|kafka_errors_value|Number of errors happened while publishing in kafka|

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss about code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
* View the [Ballerina performance test results](https://github.com/ballerina-platform/ballerina-lang/blob/master/performance/benchmarks/summary.md).

module io.ballerina.observe.metrics.prometheus {
    requires io.ballerina.runtime;
    requires io.ballerina.config;

    provides io.ballerina.runtime.observability.metrics.spi.MetricReporterFactory
            with io.ballerina.observe.metrics.prometheus.PrometheusMetricsReporterFactory;
}

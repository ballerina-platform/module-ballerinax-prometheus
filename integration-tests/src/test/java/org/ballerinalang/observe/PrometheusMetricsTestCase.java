/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.ballerinalang.observe;

import org.ballerinalang.test.context.BServerInstance;
import org.ballerinalang.test.util.HttpClientRequest;
import org.testng.Assert;
import org.testng.annotations.AfterTest;
import org.testng.annotations.BeforeTest;
import org.testng.annotations.Test;

import java.io.File;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import static io.ballerina.runtime.observability.ObservabilityConstants.CONFIG_METRICS_ENABLED;
import static io.ballerina.runtime.observability.ObservabilityConstants.CONFIG_TABLE_METRICS;

/**
 * Integration test for Prometheus extension.
 */
public class PrometheusMetricsTestCase extends BaseTestCase {
    private static BServerInstance serverInstance;

    private static final File RESOURCES_DIR = Paths.get("src", "test", "resources", "bal").toFile();
    private static final Pattern PROMETHEUS_METRIC_VALUE_REGEX = Pattern.compile("[-+]?\\d*\\.?\\d+([eE][-+]?\\d+)?");
    private static final String PROMETHEUS_METRICS_URL = "http://localhost:9797/metrics";
    private static final String TEST_RESOURCE_URL = "http://localhost:9091/prometheus-test/sum";

    @BeforeTest
    private void setup() throws Exception {
        serverInstance = new BServerInstance(balServer);
    }

    @AfterTest
    private void cleanUpServer() throws Exception {
        serverInstance.shutdownServer();
    }

    @Test
    public void testMetrics() throws Exception {
        final Map<String, Pattern> expectedMetrics = new HashMap<>();
        expectedMetrics.put("response_time_seconds_value{service=\"metricsTest\",src_module=\"_anon/.:0.0.0\"," +
                "http_status_code_group=\"2xx\",src_remote=\"true\",src_position=\"metrics_test.bal:57:20\"," +
                "action=\"respond\",resource=\"getProduct\",connector_name=\"ballerina/http/Caller\",}",
                PROMETHEUS_METRIC_VALUE_REGEX);
        expectedMetrics.put("response_time_seconds_value{service=\"metricsTest\"," +
                "src_position=\"metrics_test.bal:36:5\",connector_name=\"http\",src_module=\"_anon/.:0.0.0\"," +
                "src_entry_point_resource=\"true\",protocol=\"http\",resource=\"getProduct\",http_url=\"/test\"," +
                "http_method=\"GET\",}",
                PROMETHEUS_METRIC_VALUE_REGEX);
        expectedMetrics.put("response_time_seconds_value{service=\"metricsTest\",function=\"getQuery\"," +
                "resource=\"getProduct\",src_position=\"metrics_test.bal:37:63\",src_module=\"_anon/.:0.0.0\",}",
                PROMETHEUS_METRIC_VALUE_REGEX);
        expectedMetrics.put("response_time_nanoseconds_total_value{service=\"metricsTest\"," +
                "src_module=\"_anon/.:0.0.0\",http_status_code_group=\"2xx\",src_remote=\"true\"," +
                "src_position=\"metrics_test.bal:57:20\",action=\"respond\",resource=\"getProduct\"," +
                "connector_name=\"ballerina/http/Caller\",}",
                PROMETHEUS_METRIC_VALUE_REGEX);
        expectedMetrics.put("response_time_nanoseconds_total_value{service=\"metricsTest\"," +
                "src_position=\"metrics_test.bal:36:5\",connector_name=\"http\",src_module=\"_anon/.:0.0.0\"," +
                "src_entry_point_resource=\"true\",protocol=\"http\",resource=\"getProduct\",http_url=\"/test\"," +
                "http_method=\"GET\",}",
                PROMETHEUS_METRIC_VALUE_REGEX);
        expectedMetrics.put("response_time_nanoseconds_total_value{service=\"metricsTest\",function=\"getQuery\"," +
                "resource=\"getProduct\",src_position=\"metrics_test.bal:37:63\",src_module=\"_anon/.:0.0.0\",}",
                PROMETHEUS_METRIC_VALUE_REGEX);

        final String[] runtimeArgs = new String[]{
                "--" + CONFIG_METRICS_ENABLED + "=true",
                "--" + CONFIG_TABLE_METRICS + ".statistic.percentiles=0.5, 0.75, 0.98, 0.99, 0.999"
        };
        final String balFile = Paths.get(RESOURCES_DIR.getAbsolutePath(), "01_prometheus_test.bal").toFile()
                .getAbsolutePath();
        serverInstance.startServer(balFile, null, runtimeArgs, new int[] { 9091 });

        // Send requests to generate metrics
        int i = 0;
        while (i < 5) {
            String responseData = HttpClientRequest.doGet(TEST_RESOURCE_URL).getData();
            Assert.assertEquals(responseData, "Sum: 53");
            i++;
        }

        // Read metrics from Prometheus endpoint
        String prometheusResponseData = HttpClientRequest.doGet(PROMETHEUS_METRICS_URL).getData();
        List<String> metricsList = Arrays.stream(prometheusResponseData.split("\n"))
                .filter(s -> !s.startsWith("#"))
                .collect(Collectors.toList());

        Assert.assertTrue(metricsList.size() != 0);
        int count = 0;
        for (String line : metricsList) {
            int index = line.lastIndexOf(" ");
            String key = line.substring(0, index);
            String value = line.substring(index + 1);
            Pattern pattern = expectedMetrics.get(key);
            if (pattern != null) {
                count++;
                Assert.assertTrue(pattern.matcher(value).find(),
                        "Unexpected value found for metric " + key + ". Value: " + value + ", Pattern: "
                                + pattern.pattern() + " Complete line: " + line);
            }
        }
        Assert.assertEquals(count, expectedMetrics.size(), "metrics count is not equal to the expected metrics count.");
    }
}

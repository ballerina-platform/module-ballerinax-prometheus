/*
 *  Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */
package org.ballerinalang.observe.metrics.prometheus;

import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.observability.metrics.spi.MetricReporterFactory;

import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.util.Properties;

import static io.ballerina.runtime.api.constants.RuntimeConstants.BALLERINA_BUILTIN_PKG_PREFIX;

/**
 * This is the reporter extension for the Prometheus.
 *
 * @since 0.980.0
 */
public class PrometheusMetricsReporterFactory implements MetricReporterFactory {
    private static final PrintStream console = System.out;

    private static final String REPORTER_NAME = "prometheus";

    private static final String REPORTER_PROPERTIES_FILE = "prometheus-reporter.properties";
    private static final String MODULE_VERSION_PROPERTY_KEY = "moduleVersion";
    private static final String PROMETHEUS_PACKAGE = "prometheus";

    @Override
    public String getName() {
        return REPORTER_NAME;
    }

    @Override
    public BObject getReporterBObject() {
        String prometheusModuleVersion;
        try {
            InputStream stream = getClass().getClassLoader().getResourceAsStream(REPORTER_PROPERTIES_FILE);
            Properties reporterProperties = new Properties();
            reporterProperties.load(stream);
            prometheusModuleVersion = (String) reporterProperties.get(MODULE_VERSION_PROPERTY_KEY);
        } catch (IOException | ClassCastException e) {
            console.println("ballerina: unexpected failure in detecting Prometheus extension version");
            return null;
        }
        Module prometheusModule = new Module(BALLERINA_BUILTIN_PKG_PREFIX, PROMETHEUS_PACKAGE, prometheusModuleVersion);
        return ValueCreator.createObjectValue(prometheusModule, "MetricReporter");
    }
}

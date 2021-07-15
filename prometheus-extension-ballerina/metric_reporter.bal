// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/http;
import ballerina/lang.'string as str;
import ballerina/observe;
import ballerina/regex;

const REPORTER_NAME = "prometheus";

configurable string host = "0.0.0.0";
configurable int port = 9797;

const string METRIC_TYPE_GAUGE = "gauge";
const string METRIC_TYPE_SUMMARY = "summary";
const string EMPTY_STRING = "";
const string NEW_LINE = "\n";

const string EXPIRY_TAG = "timeWindow";
const string PERCENTILE_TAG = "quantile";

isolated function init() {
    if (observe:isMetricsEnabled() && observe:getMetricsReporter() == REPORTER_NAME) {
        error? err = startReporter(host, port);
        if (err is error) {
            io:println("error: failed to start prometheus metrics reporter");
        } else {
            io:println(string `ballerina: started Prometheus HTTP listener ${host} : ${port}`);
        }
    }
}

# Start a server to serve prometheus metrics.
#
# + host - The host to which the prometheus service should bind to
# + port - The port to which the prometheus service should bind to
# + return - An error if starting the prometheus service failed
isolated function startReporter(string host, int port) returns error? {
    http:Listener httpListener = check new(port, config = {
        host: host
    });
    service object {} prometheusReporter =
        service object {
            # This method retrieves all metrics registered in the ballerina metrics registry,
            # and reformats based on the expected format by prometheus server.
            @http:ResourceConfig {
                produces: ["application/text"]
            }
            resource function get metrics(http:Caller caller) {
                observe:Metric?[] metrics = observe:getAllMetrics();
                string[] payload = [];
                // string payload = EMPTY_STRING;
                foreach var m in metrics {
                    observe:Metric metric = <observe:Metric> m;
                    string qualifiedMetricName = getEscapedName(metric.name);
                    string metricReportName = getMetricName(qualifiedMetricName, "value");
                    payload.push(generateMetricHelp(metricReportName, metric.desc));
                    payload.push(generateMetricInfo(metricReportName, metric.metricType));
                    payload.push(generateMetric(metricReportName, metric.tags, metric.value));
                    // payload += generateMetricHelp(metricReportName, metric.desc);
                    // payload += generateMetricInfo(metricReportName, metric.metricType);
                    // payload += generateMetric(metricReportName, metric.tags, metric.value);
                    if ((str:toLowerAscii(metric.metricType) == (METRIC_TYPE_GAUGE)) && metric.summary !== ()){
                        map<string> tags = metric.tags;
                        observe:Snapshot[]? summaries = metric.summary;
                        if (summaries is ()) {
                            payload.push(NEW_LINE);
                        } else {
                            foreach var aSnapshot in summaries {
                                tags[EXPIRY_TAG] = aSnapshot.timeWindow.toString();
                                payload.push(generateMetricHelp(qualifiedMetricName, "A Summary of " +  qualifiedMetricName + " for window of "
                                                            + aSnapshot.timeWindow.toString()));
                                payload.push(generateMetricInfo(qualifiedMetricName, METRIC_TYPE_SUMMARY));
                                payload.push(generateMetric(getMetricName(qualifiedMetricName, "mean"), tags, aSnapshot.mean));
                                payload.push(generateMetric(getMetricName(qualifiedMetricName, "max"), tags, aSnapshot.max));
                                payload.push(generateMetric(getMetricName(qualifiedMetricName, "min"), tags, aSnapshot.min));
                                payload.push(generateMetric(getMetricName(qualifiedMetricName, "stdDev"), tags, aSnapshot.stdDev));
                                // payload += generateMetricHelp(qualifiedMetricName, "A Summary of " +  qualifiedMetricName + " for window of "
                                //                             + aSnapshot.timeWindow.toString());
                                // payload += generateMetricInfo(qualifiedMetricName, METRIC_TYPE_SUMMARY);
                                // payload += generateMetric(getMetricName(qualifiedMetricName, "mean"), tags, aSnapshot.mean);
                                // payload += generateMetric(getMetricName(qualifiedMetricName, "max"), tags, aSnapshot.max);
                                // payload += generateMetric(getMetricName(qualifiedMetricName, "min"), tags, aSnapshot.min);
                                // payload += generateMetric(getMetricName(qualifiedMetricName, "stdDev"), tags, aSnapshot.stdDev);
                                foreach var percentileValue in aSnapshot.percentileValues  {
                                    tags[PERCENTILE_TAG] = percentileValue.percentile.toString();
                                    payload.push(generateMetric(qualifiedMetricName, tags, percentileValue.value));
                                    // payload += generateMetric(qualifiedMetricName, tags, percentileValue.value);
                                }
                                _ = tags.remove(EXPIRY_TAG);
                                _ = tags.remove(PERCENTILE_TAG);
                            }
                        }
                    }
                }
                string stringPayload = str:'join("\n", ...payload);
                checkpanic caller->respond(stringPayload);
            }
        };
    check httpListener.attach(prometheusReporter, "/");
    check httpListener.start();
}

# This util function creates the type description based on the prometheus format for the specific metric.
#
# + name - Name of the Metric.
# + metricType - Type of Metric.
# + return - Formatted metric information.
isolated function generateMetricInfo(string name, string metricType) returns string {
    return string `# TYPE ${name} ${metricType}`;
}

# This util function creates the metric help description based on the prometheus format for the specific metric.
#
# + name - Name of the Metric.
# + description - Description of the Metric.
# + return - Formatted metric description information.
isolated function generateMetricHelp(string name, string description) returns string {
    if (description != EMPTY_STRING) {
        return string `# HELP ${name} ${description}`;
    }
    return EMPTY_STRING;
}

# This util function creates the metric along with its name, labels, and values based on the prometheus
# format for the specific metric.
#
# + name - Name of the Metric.
# + labels - Labels attached to the Metric.
# + value - Values attached to the Metric.
# + return - Formatted Metric.
isolated function generateMetric(string name, map<string>? labels, int|float value) returns string {
    float floatValue = (value is int) ? <float> value : value;

    if (labels is map<string>) {
        string strLabels = getTagsString(labels);
        return string `${name}${strLabels} ${floatValue.toString()}`;
    } else {
        return string `${name} ${floatValue.toString()}`;
    }
}

# Generate the prometheus tags string.
#
# + labels - map of labels to be converted to tags string
# + return - prometheus tags string
isolated function getTagsString(map<string> labels) returns string {
    string[] tags = [];
    foreach var [key, value] in labels.entries() {
        string labelKey = getEscapedName(key);
        string entry = string `${labelKey}="${getEscapedLabelValue(value)}"`;
        tags.push(entry);
    }
    if (tags.length() == 0) {
        return "";
    }
    return string `{${str:'join(",", ...tags)},}`;
}

# Only [a-zA-Z0-9:_] are valid in metric names, any other characters
# should be sanitized to an underscore. ref: Metrics Naming[1].
# [1] https://prometheus.io/docs/instrumenting/writing_exporters/#naming
#
# + str - string to be escaped.
# + return - escaped string.
isolated function getEscapedName(string str) returns string {
    return regex:replaceAll(str, "[^a-zA-Z0-9:_]", "_");
}

# Only [^a-zA-Z0-9\\/.:_* ] are valid in metric lable values, any other characters
# should be sanitized to an underscore.
#
# + str - string to be escaped.
# + return - escaped string.
isolated function getEscapedLabelValue(string str) returns string {
    return regex:replaceAll(str, "[^a-zA-Z0-9\\/.:_* ]", "_");
}

# Add the summary type name to summary type metrics.
#
# + name - name of the metric
# + summaryType - type of the summary metric
# + return - name of the summary type metric
isolated function getMetricName(string name, string summaryType) returns string {
    return string `${name}_${summaryType}`;
}

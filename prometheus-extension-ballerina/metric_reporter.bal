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
            io:println(string `ballerina: started Prometheus HTTP listener ${host}:${port}`);
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
    http:Service prometheusReporter =
        service object {
            # This method retrieves all metrics registered in the ballerina metrics registry,
            # and reformats based on the expected format by prometheus server.
            resource function get metrics(http:Caller caller) {
                observe:Metric?[] metrics = observe:getAllMetrics();
                map<string[]> payload = {};
                foreach var m in metrics {
                    observe:Metric metric = <observe:Metric> m;
                    string qualifiedMetricName = getEscapedName(metric.name);
                    string metricReportName = getMetricName(qualifiedMetricName, "value");
                    if !payload.hasKey(metricReportName) {
                        payload[metricReportName] = [];
                        (<string[]> payload[metricReportName]).push(generateMetricHelp(metricReportName, metric.desc));
                        (<string[]> payload[metricReportName]).push(generateMetricInfo(metricReportName, metric.metricType));
                    }
                    (<string[]> payload[metricReportName]).push(generateMetric(metricReportName, metric.tags, metric.value));
                    if ((str:toLowerAscii(metric.metricType) == METRIC_TYPE_GAUGE) && !(metric.summary is ())){
                        map<string> tags = metric.tags;
                        observe:Snapshot[] summaries = <observe:Snapshot[]> metric.summary;
                        foreach var aSnapshot in summaries {
                            tags[EXPIRY_TAG] = aSnapshot.timeWindow.toString();
                            if !payload.hasKey(qualifiedMetricName) {
                                payload[qualifiedMetricName] = [];
                                (<string[]> payload[qualifiedMetricName]).push(generateMetricHelp(qualifiedMetricName, string `A summary of ${
                                    qualifiedMetricName}`));
                                (<string[]> payload[qualifiedMetricName]).push(generateMetricInfo(qualifiedMetricName, METRIC_TYPE_SUMMARY));
                            }

                            string meanMetricName = getMetricName(qualifiedMetricName, "mean");
                            if !payload.hasKey(meanMetricName) {
                                payload[meanMetricName] = [];
                                (<string[]> payload[meanMetricName]).push(generateMetricHelp(meanMetricName, string `Mean of ${
                                    qualifiedMetricName}`));
                                (<string[]> payload[meanMetricName]).push(generateMetricInfo(meanMetricName, METRIC_TYPE_GAUGE));
                            }
                            (<string[]> payload[meanMetricName]).push(generateMetric(meanMetricName, tags, aSnapshot.mean));
                            
                            string maxMetricName = getMetricName(qualifiedMetricName, "max");
                            if !payload.hasKey(maxMetricName) {
                                payload[maxMetricName] = [];
                                (<string[]> payload[maxMetricName]).push(generateMetricHelp(maxMetricName, string `Maximum of ${
                                    qualifiedMetricName}`));
                                (<string[]> payload[maxMetricName]).push(generateMetricInfo(maxMetricName, METRIC_TYPE_GAUGE));
                            }
                            (<string[]> payload[maxMetricName]).push(generateMetric(maxMetricName, tags, aSnapshot.max));

                            string minMetricName = getMetricName(qualifiedMetricName, "min");
                            if !payload.hasKey(minMetricName) {
                                payload[minMetricName] = [];
                                (<string[]> payload[minMetricName]).push(generateMetricHelp(minMetricName, string `Minimum of ${
                                    qualifiedMetricName}`));
                                (<string[]> payload[minMetricName]).push(generateMetricInfo(minMetricName, METRIC_TYPE_GAUGE));
                            }
                            (<string[]> payload[minMetricName]).push(generateMetric(minMetricName, tags, aSnapshot.min));

                            string stdDevMetricName = getMetricName(qualifiedMetricName, "stdDev");
                            if !payload.hasKey(stdDevMetricName) {
                                payload[stdDevMetricName] = [];
                                (<string[]> payload[stdDevMetricName]).push(generateMetricHelp(stdDevMetricName, string `Standard deviation of ${
                                    qualifiedMetricName}`));
                                (<string[]> payload[stdDevMetricName]).push(generateMetricInfo(stdDevMetricName, METRIC_TYPE_GAUGE));
                            }
                            (<string[]> payload[stdDevMetricName]).push(generateMetric(stdDevMetricName, tags, aSnapshot.stdDev));

                            foreach var percentileValue in aSnapshot.percentileValues  {
                                tags[PERCENTILE_TAG] = percentileValue.percentile.toString();
                                (<string[]> payload[qualifiedMetricName]).push(generateMetric(qualifiedMetricName, tags, percentileValue.value));
                            }
                            _ = tags.remove(PERCENTILE_TAG);
                        }
                    }
                }

                string stringPayload = string:'join("\n", ...payload.map(arr => string:'join("\n", ...arr)).toArray());
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
    string:RegExp regExp = re `[^a-zA-Z0-9:_]`;
    return regExp.replaceAll(str, "_");
}

# Only [^a-zA-Z0-9\\/.:_* ] are valid in metric lable values, any other characters
# should be sanitized to an underscore.
#
# + str - string to be escaped.
# + return - escaped string.
isolated function getEscapedLabelValue(string str) returns string {
    string:RegExp regExp = re `[^a-zA-Z0-9\\/.:_* ]`;
    return regExp.replaceAll(str, "_");
}

# Add the summary type name to summary type metrics.
#
# + name - name of the metric
# + summaryType - type of the summary metric
# + return - name of the summary type metric
isolated function getMetricName(string name, string summaryType) returns string {
    return string `${name}_${summaryType}`;
}

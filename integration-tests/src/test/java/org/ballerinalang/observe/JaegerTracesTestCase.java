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
import org.ballerinalang.test.context.LogLeecher;
import org.ballerinalang.test.util.HttpClientRequest;
import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.io.File;
import java.nio.file.Paths;

import static io.ballerina.runtime.observability.ObservabilityConstants.CONFIG_TRACING_ENABLED;

/**
 * Integration test for Jaeger extension.
 */
public class JaegerTracesTestCase extends BaseTestCase {
    private BServerInstance serverInstance;

    private static final File RESOURCES_DIR = Paths.get("src", "test", "resources", "bal").toFile();
    private static final String TEST_RESOURCE_URL = "http://localhost:9091/test/sum";

    @BeforeMethod
    public void setup() throws Exception {
        serverInstance = new BServerInstance(balServer);
    }

    @AfterMethod
    public void cleanUpServer() throws Exception {
        serverInstance.shutdownServer();
    }

    @Test
    public void testJaegerMetrics() throws Exception {
        LogLeecher jaegerServerLogLeecher = new LogLeecher(
                "ballerina: started publishing tracers to Jaeger on localhost:5775");
        serverInstance.addLogLeecher(jaegerServerLogLeecher);
        LogLeecher errorLogLeacher = new LogLeecher("error");
        serverInstance.addErrorLogLeecher(errorLogLeacher);

        final String[] runtimeArgs = new String[]{
                "--" + CONFIG_TRACING_ENABLED + "=true",
        };
        final String balFile = Paths.get(RESOURCES_DIR.getAbsolutePath(), "01_http_svc_test.bal").toFile()
                .getAbsolutePath();
        serverInstance.startServer(balFile, null, runtimeArgs, new int[] { 9091 });
        jaegerServerLogLeecher.waitForText(1000);

        // Send requests to generate metrics
        int i = 0;
        while (i < 5) {
            String responseData = HttpClientRequest.doGet(TEST_RESOURCE_URL).getData();
            Assert.assertEquals(responseData, "Sum: 53");
            i++;
        }
        Thread.sleep(1000);

        Assert.assertFalse(errorLogLeacher.isTextFound(), "Unexpected error log found");
    }

    @Test
    public void testJaegerDisabled() throws Exception {
        LogLeecher jaegerServerLogLeecher = new LogLeecher(
                "ballerina: started publishing tracers to Jaeger on localhost:5775");
        serverInstance.addLogLeecher(jaegerServerLogLeecher);
        LogLeecher errorLogLeacher = new LogLeecher("error");
        serverInstance.addErrorLogLeecher(errorLogLeacher);

        final String balFile = Paths.get(RESOURCES_DIR.getAbsolutePath(), "01_http_svc_test.bal").toFile()
                .getAbsolutePath();
        serverInstance.startServer(balFile, null, null, new int[] { 9091 });

        String responseData = HttpClientRequest.doGet(TEST_RESOURCE_URL).getData();
        Assert.assertEquals(responseData, "Sum: 53");
        Assert.assertFalse(jaegerServerLogLeecher.isTextFound(), "Jaeger extension not expected to start");
        Assert.assertFalse(errorLogLeacher.isTextFound(), "Unexpected error log found");
    }
}

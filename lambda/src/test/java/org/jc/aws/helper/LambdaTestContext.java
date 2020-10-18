package org.jc.aws.helper;

import com.amazonaws.services.lambda.runtime.*;

import java.util.HashMap;
import java.util.Map;

public class LambdaTestContext implements Context {
    @Override
    public String getAwsRequestId() {
        return "dummy-request-id-010001";
    }

    @Override
    public String getLogGroupName() {
        return "dummy-log-group";
    }

    @Override
    public String getLogStreamName() {
        return "test-log-stream-name";
    }

    @Override
    public String getFunctionName() {
        return "DBChangeCapture.handleRequest";
    }

    @Override
    public String getFunctionVersion() {
        return "latest";
    }

    @Override
    public String getInvokedFunctionArn() {
        return "arn:aws:lambda:region:account:dummy";
    }

    @Override
    public CognitoIdentity getIdentity() {
        return new CognitoIdentity() {
            @Override
            public String getIdentityId() {
                return "dummyId";
            }

            @Override
            public String getIdentityPoolId() {
                return "dummyPool";
            }
        };
    }

    @Override
    public ClientContext getClientContext() {
        return new ClientContext() {
            @Override
            public Client getClient() {
                return new Client() {
                    @Override
                    public String getInstallationId() {
                        return "dummyId";
                    }

                    @Override
                    public String getAppTitle() {
                        return "test";
                    }

                    @Override
                    public String getAppVersionName() {
                        return "latest";
                    }

                    @Override
                    public String getAppVersionCode() {
                        return "latest";
                    }

                    @Override
                    public String getAppPackageName() {
                        return "test";
                    }
                };
            }

            @Override
            public Map<String, String> getCustom() {
                return new HashMap<>();
            }

            @Override
            public Map<String, String> getEnvironment() {
                return new HashMap<>();
            }
        };
    }

    @Override
    public int getRemainingTimeInMillis() {
        return 900000;
    }

    @Override
    public int getMemoryLimitInMB() {
        return 3000;
    }

    @Override
    public LambdaLogger getLogger() {
        return new LambdaLogger() {
            @Override
            public void log(String s) {
                System.out.println(s);
            }

            @Override
            public void log(byte[] bytes) {
                System.out.println(bytes.toString());
            }
        };
    }
}

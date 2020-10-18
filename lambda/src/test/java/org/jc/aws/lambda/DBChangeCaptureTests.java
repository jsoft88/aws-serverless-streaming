package org.jc.aws.lambda;

import cloud.localstack.LocalstackTestRunner;
import com.amazonaws.auth.AWSCredentials;
import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.client.builder.AwsClientBuilder;
import com.amazonaws.services.kinesisfirehose.AmazonKinesisFirehose;
import com.amazonaws.services.kinesisfirehose.AmazonKinesisFirehoseClientBuilder;
import com.amazonaws.services.kinesisfirehose.model.ListDeliveryStreamsRequest;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent;
import org.jc.aws.helper.LambdaTestContext;
import org.junit.Test;
import org.junit.jupiter.api.Assertions;
import org.junit.runner.RunWith;
import static org.mockito.Mockito.*;

import java.nio.ByteBuffer;
import java.util.Collections;
import static com.github.stefanbirkner.systemlambda.SystemLambda.*;

@RunWith(LocalstackTestRunner.class)
public class DBChangeCaptureTests {

    private static final String TEST_REGION = "test-region";
    private static final String TEST_STREAM_NAME = "test-stream-name";
    private static final String TEST_ENDPOINT = "http://localhost:4566/";

    private String envValue(String name) {
        if (name.equals(DBChangeCapture.KINESIS_ENDPOINT)) return DBChangeCaptureTests.TEST_ENDPOINT;
        if (name.equals(DBChangeCapture.KINESIS_REGION)) return DBChangeCaptureTests.TEST_REGION;
        if (name.equals(DBChangeCapture.KINESIS_STREAM_NAME)) return DBChangeCaptureTests.TEST_STREAM_NAME;

        return "";
    }
    @Test
    public void testExceptionThrownWhenFirehoseIsNotActive() {
        final DBChangeCapture ccHandler = spy(new DBChangeCapture());

        when(ccHandler.getEnvValue(anyString())).thenAnswer(c -> this.envValue(c.getArguments()[0].toString()));

        final KinesisEvent event = new KinesisEvent();
        event.setRecords(Collections.singletonList(new KinesisEvent.KinesisEventRecord()));
        doReturn(new Boolean(false)).when(ccHandler).isFirehoseActive();

        Exception ex = Assertions.assertThrows(
                RuntimeException.class,
                () -> ccHandler.handleRequest(event, new LambdaTestContext())
        );
        Assertions.assertEquals(ex.getMessage(), "Firehose status is not active.");
    }

    @Test
    public void testWhenFirehoseActiveEventIsSent() {
        AmazonKinesisFirehose firehose = AmazonKinesisFirehoseClientBuilder
                .standard()
                .withEndpointConfiguration(new AwsClientBuilder.EndpointConfiguration(DBChangeCaptureTests.TEST_ENDPOINT, DBChangeCapture.KINESIS_REGION))
                .withCredentials(new AWSStaticCredentialsProvider(new AWSCredentials() {
                    @Override
                    public String getAWSAccessKeyId() {
                        return "";
                    }

                    @Override
                    public String getAWSSecretKey() {
                        return "";
                    }
                }))
                .build();
        final DBChangeCapture ccHandler = spy(new DBChangeCapture(firehose));

        when(ccHandler.getEnvValue(anyString())).thenAnswer(c -> this.envValue(c.getArguments()[0].toString()));

        KinesisEvent.Record kinesisRecord = new KinesisEvent.Record();
        kinesisRecord.setData(ByteBuffer.wrap("dummy-data".getBytes()));

        final KinesisEvent event = new KinesisEvent();
        KinesisEvent.KinesisEventRecord rec = new KinesisEvent.KinesisEventRecord();
        rec.setKinesis(kinesisRecord);
        event.setRecords(Collections.singletonList(rec));

        doReturn(new Boolean(true)).when(ccHandler).isFirehoseActive();
        ccHandler.handleRequest(event, new LambdaTestContext());

        Assertions.assertEquals(firehose.listDeliveryStreams(new ListDeliveryStreamsRequest()).getDeliveryStreamNames().size(), 1);
    }
}

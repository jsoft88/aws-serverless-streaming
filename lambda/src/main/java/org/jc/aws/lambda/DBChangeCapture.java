package org.jc.aws.lambda;

import com.amazonaws.client.builder.AwsClientBuilder;
import com.amazonaws.services.kinesisfirehose.AmazonKinesisFirehose;
import com.amazonaws.services.kinesisfirehose.AmazonKinesisFirehoseClientBuilder;
import com.amazonaws.services.kinesisfirehose.model.DeliveryStreamStatus;
import com.amazonaws.services.kinesisfirehose.model.DescribeDeliveryStreamRequest;
import com.amazonaws.services.kinesisfirehose.model.PutRecordBatchRequest;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.KinesisEvent;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class DBChangeCapture implements RequestHandler<KinesisEvent, Void> {
    public static final String KINESIS_ENDPOINT = "kinesisEndpoint";
    public static final String KINESIS_REGION = "kinesisRegion";
    public static final String KINESIS_STREAM_NAME = "kinesisStreamName";
    public static final String KINESIS_SHARDS = "kinesisShards";

    private AmazonKinesisFirehose kinesisFirehose = null;
    private String kinesisFirehoseStreamName = null;
    private String kinesisFirehoseRegion = null;
    private String kinesisFirehoseEndpoint = null;

    public DBChangeCapture(){}

    public DBChangeCapture(AmazonKinesisFirehose kinesisFirehose) {
        this.kinesisFirehose = kinesisFirehose;
    }

    public String getEnvValue(String name) {
        return System.getenv(name);
    }

    public void setup() throws RuntimeException {
        if (this.kinesisFirehose == null) {
            this.kinesisFirehoseRegion = Optional
                    .ofNullable(this.getEnvValue(DBChangeCapture.KINESIS_REGION))
                    .orElseThrow(() -> new RuntimeException("Missing parameter region"));
            this.kinesisFirehoseEndpoint = Optional
                    .ofNullable(this.getEnvValue(DBChangeCapture.KINESIS_ENDPOINT))
                    .orElseThrow(() -> new RuntimeException("Missing parameter firehose endpoint"));
            this.kinesisFirehose = AmazonKinesisFirehoseClientBuilder
                    .standard()
                    .withEndpointConfiguration(new AwsClientBuilder.EndpointConfiguration(
                            this.kinesisFirehoseEndpoint, this.kinesisFirehoseRegion))
                    .build();
            this.kinesisFirehoseStreamName = Optional
                    .ofNullable(this.getEnvValue(DBChangeCapture.KINESIS_STREAM_NAME))
                    .orElseThrow(() -> new RuntimeException("Missing parameter firehose stream name"));
        }
    }

    // TODO: Ideally should be private, but needs more time to figure out Powermockito
    public boolean isFirehoseActive() {
        // get current firehose status
        DescribeDeliveryStreamRequest describeReq = new DescribeDeliveryStreamRequest()
                .withDeliveryStreamName(this.kinesisFirehoseStreamName);
        String status = this.kinesisFirehose
                .describeDeliveryStream(describeReq)
                .getDeliveryStreamDescription().getDeliveryStreamStatus();
        return (DeliveryStreamStatus.valueOf(status) != DeliveryStreamStatus.ACTIVE);
    }

    @Override
    public Void handleRequest(KinesisEvent event, Context context) {
        this.setup();
        if (!this.isFirehoseActive()){
            throw new RuntimeException("Firehose status is not active.");
        }

        List<com.amazonaws.services.kinesisfirehose.model.Record> records = new ArrayList<>();
        for (KinesisEvent.KinesisEventRecord rec: event.getRecords()) {
            records.add(
                    new com.amazonaws.services.kinesisfirehose.model.Record()
                            .withData(ByteBuffer.wrap(rec.getKinesis().getData().array()))
            );
        }
        PutRecordBatchRequest putBatchReq = new PutRecordBatchRequest();
        putBatchReq.setRecords(records);
        putBatchReq.setDeliveryStreamName(this.kinesisFirehoseStreamName);

        this.kinesisFirehose.putRecordBatch(putBatchReq);
        return null;
    }
}

import json
import boto3
from datetime import datetime
import os

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

EC2_INSTANCE_ID = os.environ["EC2_INSTANCE_ID"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

def lambda_handler(event, context):
    # TODO implement
    try:
        ec2.reboot_instances(InstanceIds=[EC2_INSTANCE_ID])

        message={
            "time": str(datetime.utcnow()),
            "action" : "EC2 rebooted instance triggered",
            "instance-id": EC2_INSTANCE_ID,
            "source": "Sumo Logic Alert",
            "recieved_event" : event
        }

        sns.publish(
            TopicArn= SNS_TOPIC_ARN,
            Subject="EC2 Restart Triggered by sumo logic",
            Message = json.dumps(message, indent=2)
        )
        return {
            'statusCode': 200,
            "body" : "Ec2 rebooted and sns notifications sent"
        }

    except Exception as e:
        print(e)
        raise e
provider "aws" {
    region = var.region
}

resource "aws_sns_topic" "sumo_alert_topic" {
    name = "sumo-alert-topic"
}

resource "aws_sns_topic_subscription" "email_sub" {
    topic_arn = aws_sns_topic.sumo_alert_topic.arn
    protocol = "email"
    endpoint = var.alert_email
}

resource "aws_iam_role" "lambda_role" {
    name = "sumo-ec2-restart-lambda-role-v2"

    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect" : "Allow",
            "Principal" : {
                "Service" : "lambda.amazonaws.com"
            },
            "Action" : "sts:AssumeRole"
          }
        ]
    }
    EOF
}

resource "aws_iam_policy" "lambda_policy" {
    name = "sumo-ec2-restart-policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = ["ec2:RebootInstances"]
                Resource = "*"
            },
            {
                Effect = "Allow"
                Action = ["sns:Publish"]
                Resource = aws_sns_topic.sumo_alert_topic.arn
            },
            {
                Effect = "Allow"
                Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Resource = "*"
            }
            
        ]
    })
  
}

#Attach policy

resource "aws_iam_role_policy_attachment" "attach_policy" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_policy.arn
}
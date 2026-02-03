variable "region" {
    description = "AWS region"
    type = string
}

variable "ec2_instance_id" {
    description = "Existing EC2 instance ID"
    type = string
}

variable "alert_email" {
    description = "Email for SNS alerts"
    type = string
}
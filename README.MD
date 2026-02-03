# Sumo Logic EC2 Auto Restart

## Overview
This project has three parts: (1) Sumo Logic ingests application logs and triggers a monitor when /api/data is slow (response time > 3s and count > 5 in 10 minutes), (2) the alert invokes an AWS Lambda that reboots an EC2 instance and sends an SNS email notification, and (3) Terraform (IaC) is used to define and deploy the AWS resources and document the troubleshooting done during deployment.

## Components

### 1 — Sumo Logic Implementation (Logs, Query, Monitor)

### What I implemented
- Ingested JSON application logs into Sumo Logic using an HTTP Logs source.
- Built a log query to detect slow API responses for `/api/data`.
- Created a **Monitor** using this query and validated that the monitor triggers when the threshold is met.

### Sumo Logic Query Used
(Also stored in `sumo_logic_query.txt`)

## Part 2 — AWS Lambda + SNS Notifications + Monitor-Triggered Remediation

### Objective
Automatically remediate a detected issue by restarting an EC2 instance and notifying via email. The remediation is driven by the Sumo Logic monitor alert.

### What I Implemented
- Created an **Amazon SNS Topic** and an **Email Subscription** for notifications.
- Implemented an **AWS Lambda function** that:
  - Reboots a target **EC2 instance**
  - Publishes a confirmation message to **SNS** (email notification)
- Connected the Sumo Logic monitor alert notification to trigger the AWS workflow (end-to-end automation verified).

### AWS Components Used
- **AWS Lambda**: Executes remediation logic
- **Amazon EC2**: Target instance to reboot
- **Amazon SNS**: Sends email notification after remediation
- **CloudWatch Logs**: Stores Lambda execution logs

### Lambda Code Location
- `lambda_function/lambda_function.py`

### Configuration Approach
- Used **environment variables** in Lambda for configuration:
  - `EC2_INSTANCE_ID` (target EC2 instance to reboot)
  - `SNS_TOPIC_ARN` (SNS topic ARN used for notifications)

This avoids hardcoding values and matches AWS best practices.

### Verification Steps (How I Proved It Works)
1. Confirmed SNS email subscription (Clicked the confirmation link from AWS).
2. Invoked Lambda manually once from AWS Console to validate:
   - EC2 reboot action executed successfully
   - SNS email notification received
3. Triggered the Sumo monitor by sending test logs and confirmed:
   - Sumo monitor moved to **Triggered/Critical**
   - Lambda executed automatically (CloudWatch logs updated)
   - EC2 reboot occurred
   - SNS email notification received

### Issues Encountered and Fixes (Real Troubleshooting)
- **SNS email not received initially**  
  Cause: Email subscription was not confirmed or was deactivated.  
  Fix: Confirmed subscription from email and re-subscribed if needed.
- **UnauthorizedOperation for EC2 reboot**  
  Cause: Lambda execution role missing `ec2:RebootInstances`.  
  Fix: Attached required IAM permission to the Lambda role.
- **SNS publish error (InvalidParameter / Topic Name)**  
  Cause: Topic name was used instead of full Topic ARN.  
  Fix: Updated `SNS_TOPIC_ARN` to the correct full ARN value.

### Output / Proof
- Sumo alert email received (monitor triggered)
- EC2 reboot verified in AWS console
- SNS email notification received confirming remediation


---

## Part 3 — Terraform (Infrastructure as Code) + Approach + Errors Encountered

### Objective
Implement the AWS-side infrastructure using **Terraform** to make the solution reproducible and aligned with IaC best practices.

### Terraform Code Location
- `terraform/`

### What I Created Using Terraform
- AWS provider configuration using the required region (us-east-2).
- Variables for reusable configuration:
  - `region`
  - `ec2_instance_id` (existing EC2 instance ID used as input)
  - `alert_email` (SNS notification email)
- Resources for:
  - **SNS Topic** and **Email Subscription**
  - **IAM Role** and **IAM Policy** for Lambda execution (EC2 reboot, SNS publish, CloudWatch logs)
  - **Lambda function configuration** (depending on final implementation in Terraform)

### Why I Used Existing EC2
For this lab, I used an existing EC2 instance ID as input instead of creating a new EC2 instance through Terraform. This keeps the focus on the alert-driven automation and remediation pipeline while still enabling full verification.

### Terraform Workflow Used
- `terraform init` to initialize providers
- `terraform plan` to preview changes
- `terraform apply` to deploy resources

### Errors Encountered and How I Handled Them
Terraform and AWS resource management introduced typical real-world conflicts during iteration:

1. **ResourceConflictException (Lambda already exists)**
   - Cause: Lambda function existed from manual creation or previous runs.
   - Approach: Removed the existing Lambda or used a clean deployment approach to avoid conflicts.

2. **EntityAlreadyExists (IAM role already exists)**
   - Cause: IAM role existed in AWS but Terraform state did not track it.
   - Approach: Either delete the role for a clean lab run or import it into Terraform (preferred in production).

3. **Terraform cache/state cleanup issues**
   - Cause: `.terraform/` and `terraform.tfstate` caused mismatches across retries.
   - Approach: Cleaned local cache/state and re-ran init/plan/apply in a clean sequence.

4. **IAM trust policy formatting errors**
   - Cause: AWS IAM trust policies are strict; small formatting mistakes fail validation.
   - Approach: Corrected trust policy to a valid Lambda assume role policy and re-applied.

### Final Outcome for IaC
- Terraform code is included and demonstrates the IaC approach for provisioning key AWS resources.
- Any conflicts encountered were handled with standard DevOps approaches: clean state, delete/import, and re-apply.
- End-to-end verification was still completed through successful alert execution and SNS notifications.

### Proof / Verification
- Terraform files included under `terraform/`
- SNS subscription confirmed
- Lambda execution verified (CloudWatch logs)
- Alert pipeline verified through Sumo monitor trigger and SNS email


### 5. Recordings
- Screen and audio recordings are provided via Google Drive download links.

## Notes
Terraform deployment encountered IAM role conflicts during iteration, which were resolved manually in AWS Console. Final code reflects the intended infrastructure design.
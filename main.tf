terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.0"
        }
    }
}

provider "aws" {
    region = "us-west-2"
}

data "aws_caller_identity" "current" {
}
data "aws_region" "current" {
}
data "aws_partition" "current" {
}


locals  {
  mappings = {
    mappings = {
      TrueFalse = {
        Yes = "True"
        No = "False"
      }
      EnabledDisabled = {
        Yes = "ENABLED"
        No = "DISABLED"
      }
      Services = {
        EC2 = "ec2"
        RDS = "rds"
        Both = "ec2,rds"
      }
      Timeouts = {
        1 = "cron(0/1 * * * ? *)"
        2 = "cron(0/2 * * * ? *)"
        5 = "cron(0/5 * * * ? *)"
        10 = "cron(0/10 * * * ? *)"
        15 = "cron(0/15 * * * ? *)"
        30 = "cron(0/30 * * * ? *)"
        60 = "cron(0 0/1 * * ? *)"
      }
      Settings = {
        MetricsUrl = "https://metrics.awssolutionsbuilder.com/generic"
        MetricsSolutionId = "S00030"
      }
    }
    Send = {
      AnonymousUsage = {
        Data = "Yes"
      }
      ParameterKey = {
        UniqueId = "/Solutions/aws-instance-scheduler/UUID/"
      }
    }
  }
}


variable "scheduling_active" {
  description = "Activate or deactivate scheduling."
  type = string
  default = "Yes"
}


variable "scheduled_services" {
  description = "Scheduled Services."
  type = string
  default = "EC2"
}


variable "schedule_rds_clusters" {
  description = "Enable scheduling of Aurora clusters for RDS Service."
  type = string
  default = "No"
}


variable "create_rds_snapshot" {
  description = "Create snapshot before stopping RDS instances (does not apply to Aurora Clusters)."
  type = string
  default = "No"
}


variable "memory_size" {
  description = "Size of the Lambda function running the scheduler, increase size when processing large numbers of instances."
  type = string
  default = "128"
}


variable "use_cloud_watch_metrics" {
  description = "Collect instance scheduling data using CloudWatch metrics."
  type = string
  default = "No"
}


variable "log_retention_days" {
  description = "Retention days for scheduler logs."
  type = string
  default = "30"
}


variable "trace" {
  description = "Enable logging of detailed information in CloudWatch logs."
  type = string
  default = "No"
}


variable "enable_ssm_maintenance_windows" {
  description = "Enable the solution to load SSM Maintenance Windows, so that they can be used for EC2 instance Scheduling."
  type = string
  default = "No"
}


variable "tag_name" {
  description = "Name of tag to use for associating instance schedule schemas with service instances."
  type = string
  default = "Schedule"
}


variable "default_timezone" {
  description = "Choose the default Time Zone. Default is UTC."
  type = string
  default = "UTC"
}


variable "regions" {
  description = "List of regions in which instances are scheduled, leave blank for current region only."
  type = string
  default = ""
}


variable "cross_account_roles" {
  description = "Comma separated list of ARNs for cross account access roles. These roles must be created in all checked accounts the scheduler to start and stop instances."
  type = string
  default = ""
}


variable "started_tags" {
  description = "Comma separated list of tagname and values on the formt name=value,name=value,.. that are set on started instances"
  type = string
  default = ""
}


variable "stopped_tags" {
  description = "Comma separated list of tagname and values on the formt name=value,name=value,.. that are set on stopped instances"
  type = string
  default = ""
}


variable "scheduler_frequency" {
  description = "Scheduler running frequency in minutes."
  type = string
  default = "1"
}


variable "schedule_lambda_account" {
  description = "Schedule instances in this account."
  type = string
  default = "Yes"
}


resource "aws_cloudwatch_log_group" "scheduler_log_group" {
  name = join("", ["Ec2Scheduler-logs"])
  retention_in_days = var.log_retention_days
}


resource "aws_iam_role" "scheduler_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = [
                    "lambda.amazonaws.com",
                    "events.amazonaws.com"
                ]
        }
      },
    ]
  })
}


resource "aws_iam_policy" "scheduler_role_default_policy66_f774_b8" {
  policy = jsonencode(
  {
	 Version: "2012-10-17",
	 Statement: [
		 {
			 Action: [
				 "xray:PutTraceSegments",
				 "xray:PutTelemetryRecords"
			 ],
			 Resource: "*",
			 Effect: "Allow"
		 },
		 {
			 Action: [
				 "dynamodb:BatchGetItem",
				 "dynamodb:GetRecords",
				 "dynamodb:GetShardIterator",
				 "dynamodb:Query",
				 "dynamodb:GetItem",
				 "dynamodb:Scan",
				 "dynamodb:ConditionCheckItem",
				 "dynamodb:BatchWriteItem",
				 "dynamodb:PutItem",
				 "dynamodb:UpdateItem",
				 "dynamodb:DeleteItem"
			 ],
			 Resource: [
				 "${aws_dynamodb_table.state_table.arn}"
			 ],
			 Effect: "Allow"
		 },
		 {
			 Action: [
				 "dynamodb:DeleteItem",
				 "dynamodb:GetItem",
				 "dynamodb:PutItem",
				 "dynamodb:Query",
				 "dynamodb:Scan",
				 "dynamodb:BatchWriteItem"
			 ],
			 Resource: [
				 "${aws_dynamodb_table.config_table.arn}",
				 "${aws_dynamodb_table.maintenance_window_table.arn}"
			 ],
			 Effect: "Allow"
		 },
		 {
			 Action: [
				 "ssm:PutParameter",
				 "ssm:GetParameter"
			 ],
			 Resource: "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/Solutions/aws-instance-scheduler/UUID/*",
			 Effect: "Allow"
		 }
	 ]
  } 
)
  name = "SchedulerRoleDefaultPolicy66F774B8"
}

resource "aws_iam_policy" "ec2_permissions_b6_e87802" {
  policy = jsonencode({
    Statement = [{Action: "ec2:ModifyInstanceAttribute", Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"}, {Action: "sts:AssumeRole", Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:iam::*:role/*EC2SchedulerCross*"}]
    Version = "2012-10-17"
  })
  name = "Ec2PermissionsB6E87802"
}


resource "aws_iam_policy" "ec2_dynamo_db_policy" {
  policy = jsonencode({
    Statement = [{Action: ["ssm:GetParameter", "ssm:GetParameters"], Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/*"}, {Action: ["logs:DescribeLogStreams", "rds:DescribeDBClusters", "rds:DescribeDBInstances", "ec2:DescribeInstances", "ec2:DescribeRegions", "cloudwatch:PutMetricData", "ssm:DescribeMaintenanceWindows", "tag:GetResources"], Effect: "Allow", Resource: "*"}, {Action: ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:PutRetentionPolicy"], Effect: "Allow", Resource: ["arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*", aws_cloudwatch_log_group.scheduler_log_group.arn]}]
    Version = "2012-10-17"
  })
  name = "EC2DynamoDBPolicy"
}


resource "aws_iam_policy" "scheduler_policy" {
  policy = jsonencode({
    Statement = [{Action: ["rds:AddTagsToResource", "rds:RemoveTagsFromResource", "rds:DescribeDBSnapshots", "rds:StartDBInstance", "rds:StopDBInstance"], Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*"}, {Action: ["ec2:StartInstances", "ec2:StopInstances", "ec2:CreateTags", "ec2:DeleteTags"], Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"}, {Action: "sns:Publish", Effect: "Allow", Resource: aws_sns_topic.instance_scheduler_sns_topic.id}, {Action: "lambda:InvokeFunction", Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:Ec2Scheduler-InstanceSchedulerMain"}, {Action: ["kms:GenerateDataKey*", "kms:Decrypt"], Effect: "Allow", Resource: aws_kms_key.instance_scheduler_encryption_key.arn}]
    Version = "2012-10-17"
  })
  name = "SchedulerPolicy"
}


resource "aws_iam_policy" "scheduler_rds_policy2_e7_c328_a" {
  policy = jsonencode({
    Statement = [{Action: ["rds:DeleteDBSnapshot", "rds:DescribeDBSnapshots", "rds:StopDBInstance"], Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:*"}, {Action: ["rds:AddTagsToResource", "rds:RemoveTagsFromResource", "rds:StartDBCluster", "rds:StopDBCluster"], Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*"}]
    Version = "2012-10-17"
  })
  name = "SchedulerRDSPolicy2E7C328A"
}

resource "aws_iam_role_policy_attachment" "test-attach1" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_role_default_policy66_f774_b8.arn
}
resource "aws_iam_role_policy_attachment" "test-attach2" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.ec2_permissions_b6_e87802.arn
}
resource "aws_iam_role_policy_attachment" "test-attach3" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.ec2_dynamo_db_policy.arn
}
resource "aws_iam_role_policy_attachment" "test-attach4" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}
resource "aws_iam_role_policy_attachment" "test-attach5" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_rds_policy2_e7_c328_a.arn
}


resource "aws_kms_key" "instance_scheduler_encryption_key" {
  policy = jsonencode({
    Statement = [{Action: "kms:*", Effect: "Allow", Principal: {"AWS": join("", ["arn:", data.aws_partition.current.partition, ":iam::", data.aws_caller_identity.current.account_id, ":root"])}, Resource: "*", Sid: "default"}, {Action: ["kms:GenerateDataKey*", "kms:Decrypt"], Effect: "Allow", Principal: {"AWS": aws_iam_role.scheduler_role.arn}, Resource: "*", Sid: "Allows use of key"}, {Action: ["kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*", "kms:Put*", "kms:Update*", "kms:Revoke*", "kms:Disable*", "kms:Get*", "kms:Delete*", "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion", "kms:GenerateDataKey", "kms:TagResource", "kms:UntagResource"], Effect: "Allow", Principal: {"AWS": join("", ["arn:", data.aws_partition.current.partition, ":iam::", data.aws_caller_identity.current.account_id, ":root"])}, Resource: "*"}]
    Version = "2012-10-17"
  })
  description = "Key for SNS"
  is_enabled = "true"
  enable_key_rotation = "true"
}


resource "aws_kms_alias" "instance_scheduler_encryption_key_alias" {
  name = join("", ["alias/", "Ec2Scheduler-instance-scheduler-encryption-key"])
  target_key_id = aws_kms_key.instance_scheduler_encryption_key.arn
}


resource "aws_sns_topic" "instance_scheduler_sns_topic" {
  kms_master_key_id = aws_kms_key.instance_scheduler_encryption_key.arn
}


resource "aws_iam_role" "instanceschedulerlambda_lambda_function_service_role_ebf44_cd1" {
  assume_role_policy = jsonencode({
    Statement = [{Action: "sts:AssumeRole", Effect: "Allow", Principal: {"Service": "lambda.amazonaws.com"}}]
    Version = "2012-10-17"
  })
  inline_policy {
    name = "LambdaFunctionServiceRolePolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
          Effect   = "Allow"
          Resource: join("", ["arn:", data.aws_partition.current.partition, ":logs:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":log-group:/aws/lambda/*"]),
        },
      ]
    })                
  }
}



resource "aws_lambda_function" "main" {
    s3_bucket = join("", ["solutions-", data.aws_region.current.name])
    s3_key = "aws-instance-scheduler/v1.4.1/instance-scheduler.zip"
    role = aws_iam_role.scheduler_role.arn
    description = "EC2 and RDS instance scheduler, version v1.4.1"


  environment {
    variables = {
    SCHEDULER_FREQUENCY = var.scheduler_frequency
    TAG_NAME = var.tag_name
    LOG_GROUP = aws_cloudwatch_log_group.scheduler_log_group.name
    ACCOUNT = data.aws_caller_identity.current.account_id
    ISSUES_TOPIC_ARN = aws_sns_topic.instance_scheduler_sns_topic.id
    STACK_NAME = "Ec2Scheduler"
    BOTO_RETRY = "5,10,30,0.25"
    ENV_BOTO_RETRY_LOGGING = "FALSE"
    SEND_METRICS = local.mappings["mappings"]["TrueFalse"][local.mappings["Send"]["AnonymousUsage"]["Data"]]
    SOLUTION_ID = local.mappings["mappings"]["Settings"]["MetricsSolutionId"]
    TRACE = local.mappings["mappings"]["TrueFalse"][var.trace]
    ENABLE_SSM_MAINTENANCE_WINDOWS = local.mappings["mappings"]["TrueFalse"][var.enable_ssm_maintenance_windows]
    USER_AGENT = join("", ["InstanceScheduler-Ec2Scheduler-v1.4.1"])
    USER_AGENT_EXTRA = "AwsSolution/SO0030/v1.4.1"
    METRICS_URL = local.mappings["mappings"]["Settings"]["MetricsUrl"]
    UUID_KEY = local.mappings["Send"]["ParameterKey"]["UniqueId"]
    START_EC2_BATCH_SIZE = "5"
    DDB_TABLE_NAME = aws_dynamodb_table.state_table.name
    CONFIG_TABLE = aws_dynamodb_table.config_table.name
    MAINTENANCE_WINDOW_TABLE = aws_dynamodb_table.maintenance_window_table.name
    STATE_TABLE = aws_dynamodb_table.state_table.name
  }
  }
  function_name = join("", ["Ec2Scheduler-InstanceSchedulerMain"])
  handler = "main.lambda_handler"
  memory_size = var.memory_size
  runtime = "python3.7"
  timeout = "300"
  tracing_config {
    mode = "Active"
  }
    tags = {
    stack-name = "Ec2Scheduler"
    logical-id = "Main"
  }
 
}


resource "aws_lambda_permission" "instanceschedulerlambda_lambda_function_aws_events_lambda_invoke_permission1_f8_e87_df9" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.scheduler_rule.arn
}


resource "aws_dynamodb_table" "state_table" {
  attribute {
              name= "service" 
              type= "S"
             }
  attribute {
              name= "account-region" 
              type= "S"
            }
  hash_key = "service"
  range_key = "account-region"
  name = "EC2Scheduler-StateTable-2W"
  billing_mode = "PAY_PER_REQUEST"
  point_in_time_recovery {
        enabled = true
    }
  server_side_encryption {
        enabled = true
    }
}


resource "aws_dynamodb_table" "config_table" {
  attribute {
              name= "type" 
              type= "S"
             }
  attribute {
              name= "name" 
              type= "S"
            }
  name = "EC2Scheduler-ConfigTable-2W"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "type"
  range_key = "name"
  point_in_time_recovery {
        enabled = true
    }
  server_side_encryption {
        enabled = true
    }
  // CF Property(SSESpecification) = {KMSMasterKeyId: aws_kms_key.instance_scheduler_encryption_key.arn, SSEEnabled: "True", SSEType: "KMS"}
}


resource "aws_dynamodb_table" "maintenance_window_table" {
  attribute {
              name= "Name" 
              type= "S"
             }
  attribute {
              name= "account-region" 
              type= "S"
            }
  name = "EC2Scheduler-MaintainenceTable-2W"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "Name"
  range_key = "account-region"
  point_in_time_recovery {
        enabled = true
    }
  server_side_encryption {
        enabled = true
    }
  // CF Property(SSESpecification) = {KMSMasterKeyId: aws_kms_key.instance_scheduler_encryption_key.arn, SSEEnabled: "True", SSEType: "KMS"}
}


resource "aws_cloudwatch_event_rule" "scheduler_rule" {
  description = "Instance Scheduler - Rule to trigger instance for scheduler function version v1.4.1"
  schedule_expression = local.mappings["mappings"]["Timeouts"][var.scheduler_frequency]
}

resource "aws_cloudwatch_event_target" "tarfget_lambda" {
  rule = aws_cloudwatch_event_rule.scheduler_rule.name
  arn  = aws_lambda_function.main.arn
}

/*
resource "aws_ecs_service" "scheduler_config_helper" {
  // CF Property(ServiceToken) = aws_lambda_function.main.arn
  // CF Property(timeout) = "120"
  // CF Property(config_table) = aws_dynamodb_table.config_table.arn
  // CF Property(tagname) = var.tag_name
  // CF Property(default_timezone) = var.default_timezone
  // CF Property(use_metrics) = local.mappings["mappings"]["TrueFalse"][var.use_cloud_watch_metrics]
  // CF Property(scheduled_services) = split(",", "local.mappings["mappings"]["Services"][var.scheduled_services]")
  // CF Property(schedule_clusters) = local.mappings["mappings"]["TrueFalse"][var.schedule_rds_clusters]
  // CF Property(create_rds_snapshot) = local.mappings["mappings"]["TrueFalse"][var.create_rds_snapshot]
  // CF Property(regions) = var.regions
  // CF Property(cross_account_roles) = var.cross_account_roles
  // CF Property(schedule_lambda_account) = local.mappings["mappings"]["TrueFalse"][var.schedule_lambda_account]
  // CF Property(trace) = local.mappings["mappings"]["TrueFalse"][var.trace]
  // CF Property(enable_SSM_maintenance_windows) = local.mappings["mappings"]["TrueFalse"][var.enable_ssm_maintenance_windows]
  // CF Property(log_retention_days) = var.log_retention_days
  // CF Property(started_tags) = var.started_tags
  // CF Property(stopped_tags) = var.stopped_tags
  // CF Property(stack_version) = "v1.4.1"
}
*/

output "account_id" {
  description = "Account to give access to when creating cross-account access role for cross account scenario "
  value = data.aws_caller_identity.current.account_id
}


output "configuration_table" {
  description = "Name of the DynamoDB configuration table"
  value = aws_dynamodb_table.config_table.arn
}


output "issue_sns_topic_arn" {
  description = "Topic to subscribe to for notifications of errors and warnings"
  value = aws_sns_topic.instance_scheduler_sns_topic.id
}


output "scheduler_role_arn" {
  description = "Role for the instance scheduler lambda function"
  value = aws_iam_role.scheduler_role.arn
}



output "service_instance_schedule_service_token" {
  description = "Arn to use as ServiceToken property for custom resource type Custom::ServiceInstanceSchedule"
  value = aws_lambda_function.main.arn
}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {
}


data "aws_partition" "current" {
}


variable "instance_scheduler_account" {
  description = "Account number of Instance Scheduler account to give access to manage EC2 and RDS  Instances in this account."
  type        = string
}


resource "aws_iam_role" "ec2_scheduler_cross_account_role" {
  name = "remote-EC2SchedulerCrossAccountRole-2W"
  assume_role_policy = jsonencode({
    #Statement = [{ Action : "sts:AssumeRole", Effect : "Allow", Principal : { "AWS" : "arn:${data.aws_partition.current.partition}:iam::${var.instance_scheduler_account}:root", "Service" : "lambda.amazonaws.com" } }]
    #Version   = "2012-10-17"
    Version: "2012-10-17",
    Statement: [
        {
            Effect: "Allow",
            Principal: {
                "Service": "lambda.amazonaws.com",
                "AWS": "arn:${data.aws_partition.current.partition}:iam::${var.instance_scheduler_account}:root"
            },
            Action: "sts:AssumeRole"
        }
    ]
}
  )
  path = "/"
  inline_policy {
    name = "EC2InstanceSchedulerRemote"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "rds:DeleteDBSnapshot",
            "rds:DescribeDBSnapshots",
            "rds:StopDBInstance"
          ],
          "Resource" : "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:snapshot:*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "rds:AddTagsToResource",
            "rds:RemoveTagsFromResource",
            "rds:DescribeDBSnapshots",
            "rds:StartDBInstance",
            "rds:StopDBInstance"
          ],
          "Resource" : "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:db:*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "rds:AddTagsToResource",
            "rds:RemoveTagsFromResource",
            "rds:StartDBCluster",
            "rds:StopDBCluster"
          ],
          "Resource" : "arn:${data.aws_partition.current.partition}:rds:*:${data.aws_caller_identity.current.account_id}:cluster:*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "ec2:StartInstances",
            "ec2:StopInstances",
            "ec2:CreateTags",
            "ec2:DeleteTags"
          ],
          "Resource" : "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "rds:DescribeDBClusters",
            "rds:DescribeDBInstances",
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ssm:DescribeMaintenanceWindows",
            "ssm:DescribeMaintenanceWindowExecutions",
            "tag:GetResources"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        }
      ]
    })
  }


  inline_policy {
    policy = jsonencode(
      #Statement = [{Action: "ec2:ModifyInstanceAttribute", Effect: "Allow", Resource: "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"}]
      #Version = "2012-10-17"
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Action" : "ec2:ModifyInstanceAttribute",
            "Resource" : "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
            "Effect" : "Allow"
          }
        ]
      }
    )
    name = "Ec2ModifyInstanceAttrPolicy4B693ACF"
  }
}

output "cross_account_role" {
  description = "Arn for cross account role for Instance scheduler, add this arn to the list of crossaccount roles (CrossAccountRoles) parameter of the Instance Scheduler template."
  value       = aws_iam_role.ec2_scheduler_cross_account_role.arn
}

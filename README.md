# AWS Instance Scheduler - Terraform

This repository is used to deploy the AWS Instance Scheduler via Terraform, a solution designed to automate the starting and stopping of EC2 instances to optimize compute resource usage and reduce operational costs. The Instance Scheduler is particularly useful for non-production environments, such as development, testing, or staging, where servers are not required to run 24/7.

The solution leverages AWS Lambda, a serverless compute service, to execute the logic for starting and stopping instances. The schedules for these operations are stored in Amazon DynamoDB, a fully managed NoSQL database, where administrators can define custom schedules based on their requirements. For instance, you can specify that development servers should only run during business hours on weekdays, while being shut down during evenings and weekends.

The key features of this solution include:

- __Tag-Based Scheduling:__ EC2 instances can be tagged with specific schedule identifiers, allowing for flexible and granular control over which instances are affected by each schedule.
- __Customizable Schedules:__ Administrators can define multiple schedules with different start and stop times to cater to various use cases and environments.
- __Multi-Region Support:__ The solution can be deployed to manage instances across multiple AWS regions and multi account.


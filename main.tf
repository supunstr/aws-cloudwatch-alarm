provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

locals {
 all_ec2 = zipmap ( data.aws_instances.all_ec2.ids, data.aws_instances.all_ec2.private_ips )
  #all_ec2 = zipmap ( data.aws_instances.all_ec2.ids )
}

resource "aws_sns_topic" "ec2notification" {
    name = "ec2email"
    display_name = "ec2email"
}

resource "aws_sns_topic_subscription" "sns-topic-ec2email" {
    topic_arn = aws_sns_topic.ec2notification.arn
    protocol = "email"
    endpoint = "supunstr@gmail.com"
  
}

data "aws_instances" "all_ec2" {
    instance_state_names = ["running"]
    instance_tags = {
      "name" = "test"
    }
}

locals {
  arn = "arn:aws:automate:us-east-1:ec2:recover"
}

resource "aws_cloudwatch_metric_alarm" "ec2recover" {
    for_each = local.all_ec2

    alarm_name = format("%s-ec2recover", each.key)
    alarm_description = "Created from EC2 Console"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    ok_actions =  []
    actions_enabled = "true"
    metric_name = "StatusCheckFailed_System"
    namespace = "AWS/EC2"
    statistic = "Average"
    period = "60"
    evaluation_periods = "2"
    datapoints_to_alarm = "2"
    threshold = "0.99"
    insufficient_data_actions = []
    dimensions = {
        InstanceId = each.key
    }

    alarm_actions = [ aws_sns_topic.ec2notification.arn, local.arn ]

}

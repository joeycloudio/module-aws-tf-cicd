# Instructions: Create resources for EventBridge

# Create TF Workshop Custom Event Bus
resource "random_string" "tf_workshop_event_bus" {
  length  = 4
  special = false
  upper   = false
}
resource "aws_cloudwatch_event_bus" "tf_workshop_event_bus" {
  name = "${var.project_prefix}-event_bus-${random_string.tf_workshop_event_bus.result}"
  tags = merge(
    {
      "Name" = "${var.project_prefix}-event_bus-${random_string.tf_workshop_event_bus.result}"
    },
    var.tags,
  )
}

# Create Event Bus Target to send defined events from Default Event Bus to TF Workshop Event Bus
resource "aws_cloudwatch_event_target" "default_event_bus_to_tf_workshop_event_bus" {
  for_each       = var.codepipeline_pipelines
  rule      = aws_cloudwatch_event_rule.default_event_bus_to_tf_workshop_event_bus[each.key].name
  force_destroy = var.eventbridge_rules_enable_force_destroy
  target_id = aws_cloudwatch_event_bus.tf_workshop_event_bus.name
  arn       = aws_cloudwatch_event_bus.tf_workshop_event_bus.arn
  role_arn  = aws_iam_role.eventbridge_invoke_tf_workshop_event_bus[0].arn
}

# Invoke CodePipeline
# Create rule to invoke CodePipelines when object is uploaded to the respective S3 Bucket

# Create Event Bus to invoke CodePipeline when defined events are recieved on TF Workshop Event Bus
resource "aws_cloudwatch_event_target" "module_validation_codepipeline" {
  for_each       = var.codepipeline_pipelines
  force_destroy  = var.eventbridge_rules_enable_force_destroy
  rule           = aws_cloudwatch_event_rule.invoke_codepipeline[each.key].name
  target_id      = aws_codepipeline.codepipeline[each.key].name
  arn            = aws_codepipeline.codepipeline[each.key].arn
  role_arn       = aws_iam_role.eventbridge_invoke_codepipeline.arn
  event_bus_name = aws_cloudwatch_event_bus.tf_workshop_event_bus.name
}
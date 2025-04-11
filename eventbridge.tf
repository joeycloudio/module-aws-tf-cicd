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

# Invoke CodePipeline
# Create rule to invoke CodePipelines when object is uploaded to the respective S3 Bucket
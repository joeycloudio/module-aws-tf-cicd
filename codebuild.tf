# Instructions: Dynamically create AWS CodeBuild Projects

resource "aws_codebuild_project" "codebuild" {

  for_each = var.codebuild_projects == null ? {} : var.codebuild_projects

  name          = each.value.name
  description   = each.value.description
  build_timeout = each.value.build_timeout
  service_role  = var.codebuild_service_role_arn != null ? var.codebuild_service_role_arn : aws_iam_role.codebuild_service_role[0].arn

  environment {
    compute_type                = each.value.env_compute_type
    image                       = each.value.env_image
    type                        = each.value.env_type
    image_pull_credentials_type = "SERVICE_ROLE"

    environment_variable {
    name  = "CODESTAR_CONNECTION_ARN"
    value = var.codestar_connection_arn
    }

    environment_variable {
      name  = "DOCKERHUB_SECRET_ARN"
      value = var.dockerhub_secret_arn
    }

    registry_credential {
    credential          = var.dockerhub_secret_arn
    credential_provider = "SECRETS_MANAGER"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value.path_to_build_spec

  }

  source_version = each.value.source_version

  artifacts {
    type = "CODEPIPELINE"
  }

logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = "/aws/codebuild/${each.value.name}"
      stream_name = "build-logs"
    }
  }

  tags = merge(
    {
      "Name" = each.value.name
    },
    var.tags,
  )

#   depends_on = [
#     aws_codecommit_repository.codecommit
#   ]

}
locals {
  safe_codepipeline_pipelines = var.codepipeline_pipelines == null ? {} : nonsensitive(var.codepipeline_pipelines)
}

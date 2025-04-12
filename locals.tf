locals {
  safe_codepipeline_pipelines = var.codepipeline_pipelines == null ? {} : var.codepipeline_pipelines

  tf_test_path_to_buildspec  = "${path.module}/buildspec/tf-test-buildspec.yml"
  checkov_path_to_buildspec  = "${path.module}/buildspec/checkov-buildspec.yml"
  tf_apply_path_to_buildspec = "${path.module}/buildspec/tf-apply-buildspec.yml"
}

locals {
  safe_codepipeline_pipelines = {
    for k, v in var.codepipeline_pipelines : k => merge(
      v,
      {
        stages = [for stage in v.stages : merge(
          stage,
          {
            action = [for action in stage.action : merge(
              action,
              action.provider == "GitHub" ? {
                configuration = merge(action.configuration, { OAuthToken = null })
              } : {}
            )]
          }
        )]
      }
    )
  }
}

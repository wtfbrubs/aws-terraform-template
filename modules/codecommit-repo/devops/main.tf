resource "aws_codepipeline" "codepipeline" {
  name     = format("%s-%s-%s-pipeline",var.alias, var.repo_name, var.pipeline_branch)
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName = var.repo_name
        BranchName     = var.pipeline_branch
        PollForSourceChanges = false
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.codebuild.name
      }
    }
  }
  stage {
    name = "Deploy"
    action {
      name             = "DeployToECS"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      version          = "1"
      input_artifacts  = ["build_output"]  # Assumindo que o artefato de build é chamado "build_output"

      configuration = {
        ClusterName        = var.cluster_name
        ServiceName        = var.service_name  # Substitua pelo nome do seu serviço ECS
        FileName           = "imagedefinitions.json"    # O nome do arquivo de definições de imagem ECS
        DeploymentTimeout  = 15 // Outras configurações ECS conforme necessário
      }
    }
  }

  
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = format("%s-%s-%s-pipeline",var.alias, var.repo_name, var.pipeline_branch)
}



data "aws_iam_policy_document" "assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "codepipeline_role" {
  name               = format("%s-%s-%s-pipeline-role",var.alias, var.repo_name, var.pipeline_branch)
  assume_role_policy = data.aws_iam_policy_document.assume_role_pipeline.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }
  
  statement {
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:List*"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "iam:PassRole",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = ["*"]
  }
  statement {
    effect = "Allow"
    resources = [
        var.codecommit_repo_arn
    ]
    actions = [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetRepository",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive",
        "codecommit:GitPull"
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = format("%s-%s-%s-pipeline-policy",var.alias, var.repo_name, var.pipeline_branch)
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}


resource "aws_iam_role" "codebuild_role" {
  name               = format("%s-%s-%s-build-role",var.alias, var.repo_name, var.pipeline_branch)
  assume_role_policy = data.aws_iam_policy_document.assume_role_build.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["arn:aws:ec2:*:*:network-interface/*"]

    
  }
  statement {
    effect = "Allow"
    resources = [
        var.codecommit_repo_arn
    ]
    actions = [
        "codecommit:GitPull"
    ]
  }
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_role_policy1" {
  role   = aws_iam_role.codebuild_role.name
  policy = data.aws_iam_policy_document.codebuild_policy.json
}

resource "aws_iam_role_policy_attachment" "codebuild_role_ecr_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_codebuild_project" "codebuild" {
  name           = format("%s-%s-%s-build",var.alias, var.repo_name, var.pipeline_branch)
  service_role   = aws_iam_role.codebuild_role.arn
  build_timeout  = "5"
  queued_timeout = "5"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    environment_variable {
      name  = "REPOSITORY_NAME"
      value = format("%s-%s",var.alias, var.repo_name)  // Substitua por "gasfacil-bi" ou "gasfacil-sandbox-bi" conforme necessário
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
  }
}


data "aws_iam_policy_document" "assume_role_build" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_cloudwatch_event_rule" "codecommit_event" {
  name        = format("%s-%s-%s-event-rule",var.alias, var.repo_name, var.pipeline_branch)
  description = "Trigger for CodeCommit repo events"

  event_pattern = jsonencode({
    source: ["aws.codecommit"],
    detail-type: ["CodeCommit Repository State Change"],
    resources: [var.codecommit_repo_arn],
    detail: {
      event: ["referenceCreated", "referenceUpdated"],
      referenceName: [var.pipeline_branch],
      referenceType: ["branch"]
    }
  })
}

resource "aws_cloudwatch_event_target" "codepipeline_target" {
  rule = aws_cloudwatch_event_rule.codecommit_event.name
  arn  = aws_codepipeline.codepipeline.arn

  role_arn = aws_iam_role.event_target_role.arn
}

resource "aws_iam_role" "event_target_role" {
  name = format("%s-%s-%s-event-target-role",var.alias, var.repo_name, var.pipeline_branch)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_policy" "event_target_policy" {
  name = format("%s-%s-%s-event-target-policy",var.alias, var.repo_name, var.pipeline_branch)

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Action: "codepipeline:StartPipelineExecution",
        Effect: "Allow",
        Resource: aws_codepipeline.codepipeline.arn
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "event_target_policy_attachment" {
  role       = aws_iam_role.event_target_role.name
  policy_arn = aws_iam_policy.event_target_policy.arn
}


# resource "aws_iam_role" "codedeploy_role" {
#   name = "codedeploy_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "codedeploy.amazonaws.com"
#         },
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "codedeploy_role_policy" {
#   role       = aws_iam_role.codedeploy_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
# }


# resource "aws_codedeploy_app" "ecs_app" {
#   name     = format("%s-%s-%s-app",var.alias, var.repo_name, var.pipeline_branch)
#   compute_platform = "ECS"
# }

# resource "aws_codedeploy_deployment_group" "ecs_deployment_group" {
#   app_name               = aws_codedeploy_app.ecs_app.name
#   deployment_group_name  = format("%s-%s-%s-app-grp",var.alias, var.repo_name, var.pipeline_branch)
#   service_role_arn       = aws_iam_role.codedeploy_role.arn
#   deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

#   ecs_service {
#     cluster_name = var.cluster_name
#     service_name = var.service_name
#   }
#   blue_green_deployment_config {
#     deployment_ready_option {
#       action_on_timeout = "CONTINUE_DEPLOYMENT"
#     }

#     terminate_blue_instances_on_deployment_success {
#       action                           = "TERMINATE"
#       termination_wait_time_in_minutes = 5
#     }
#   }
#   deployment_style {
#     deployment_option = "WITH_TRAFFIC_CONTROL"
#     deployment_type   = "BLUE_GREEN"
#   }
#   auto_rollback_configuration {
#     enabled = true
#     events  = ["DEPLOYMENT_FAILURE"]
#   }

#   load_balancer_info {
#     target_group_pair_info {
#       prod_traffic_route {
#         listener_arns = [var.listner_arn]
#       }

#       target_group {
#         name = var.target_group_name_blue
#       }

#       target_group {
#         name = var.target_group_name_green
#       }
      
#     }
#   }
# }


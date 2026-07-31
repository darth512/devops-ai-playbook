terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

resource "kubernetes_namespace_v1" "amazon_cloudwatch" {
  metadata {
    name = "amazon-cloudwatch"
  }
}

data "aws_iam_policy_document" "fluent_bit_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:aws-for-fluent-bit"]
    }
  }
}

resource "aws_iam_role" "fluent_bit_irsa" {
  name               = "${var.cluster_name}-fluent-bit-irsa"
  assume_role_policy = data.aws_iam_policy_document.fluent_bit_assume_role.json
}

resource "aws_iam_role_policy_attachment" "fluent_bit_cloudwatch_policy" {
  role       = aws_iam_role.fluent_bit_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "helm_release" "aws_for_fluent_bit" {
  name       = "aws-for-fluent-bit"
  namespace  = kubernetes_namespace_v1.amazon_cloudwatch.metadata[0].name
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"

  create_namespace = false

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "aws-for-fluent-bit"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.fluent_bit_irsa.arn
        }
      }
      cloudWatch = {
        region       = var.region
        logGroupName = var.log_group_name
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.fluent_bit_cloudwatch_policy
  ]
}

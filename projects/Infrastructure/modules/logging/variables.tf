variable "oidc_provider_arn" {
  description = "ARN of the EKS cluster's IAM OIDC provider"
  type        = string
}

variable "oidc_issuer_url" {
  description = "Issuer URL of the EKS cluster's OIDC provider"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region for CloudWatch Logs"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name for pod logs"
  type        = string
}

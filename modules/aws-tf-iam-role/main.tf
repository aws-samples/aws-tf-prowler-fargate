
# Prowler Cross Account IAM Role and Policy - Also used by ECS task
resource "aws_iam_role" "prowler_role" {
  name               = var.prowler_iamrole_name
  description        = "Provides Prowler EC2 instance permissions to assess security of Accounts in AWS Organization"
  assume_role_policy = data.aws_iam_policy_document.crossaccount_assume_policy.json

  tags = var.tags
}

resource "aws_iam_policy_attachment" "security_audit" {
  name       = "SecurityAudit"
  roles      = [aws_iam_role.prowler_role.name]
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_policy_attachment" "view_only_access" {
  name       = "ViewOnlyAccess"
  roles      = [aws_iam_role.prowler_role.name]
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}


resource "aws_iam_role_policy" "crossaccount_policy" {
  name       = "ProwlerPolicyAdditions"
  role      = aws_iam_role.prowler_role.id
  policy = data.aws_iam_policy_document.crossaccount_policy.json
}
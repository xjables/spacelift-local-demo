output "spacelift_role_arn" {
  value       = var.spacelift_arn != null ? aws_iam_role.spacelift_admin.arn : ""
  description = "The role in the account that whatever spacelift role/user assumes to perform actions."
}

output "planner_role_arn" {
  value       = aws_iam_role.planners.arn
  description = "The role plan-only users can assume on the CLI to generate plans."
}

output "non_planner_role_arn" {
  value       = aws_iam_role.non_planner.arn
  description = "This role is assumable by all planners, but does not have access to plan locally, demonstrating that it is the role that makes the difference."
}

# aws sts assume-role \
#     --role-arn $(aws ssm get-parameter --name /spacelift-local-demo/demo/planner_role_arn | jq -r '.Parameter.Value') \
#     --session-name "demo-mcdemoface"

# terraform plan -out demo.plan


# data "aws_ssm_parameter" "planner_role_arn" {
#     name = "/spacelift-local-demo/demo/planner_role_arn"
# }

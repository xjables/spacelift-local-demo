variable "region" {
  type    = string
  default = "us-west-2"
}

variable "spacelift_arn" {
  type     = string
  nullable = true
  default  = null
}

variable "local_planner_arns" {
  type = list(string)
}

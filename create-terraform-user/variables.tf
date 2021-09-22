variable "common_tags" {
  type        = map(string)
  description = "Tags which should be applied to all resources."
  default = {
    owner = "alex.ryndin"
    env   = "dev"
  }
}

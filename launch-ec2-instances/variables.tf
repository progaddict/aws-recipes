variable "ssh_key_name" {
  type        = string
  description = "Public SSH key name stored in the corresponding AWS region."
}

variable "common_tags" {
  type        = map(string)
  description = "Tags which should be applied to all resources."
  default = {
    owner = "alex.ryndin"
    env   = "dev"
  }
}

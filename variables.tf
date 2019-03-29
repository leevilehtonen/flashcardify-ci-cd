variable "project-name" {
  default = "flashcardify"
}

variable "region" {
  type    = "string"
  default = "eu-west-1"
}

variable "github-oauth-token" {
  type        = "string"
  description = "A valid OAuthToken to enable Code pipeline access the source"
}

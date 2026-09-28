variable "BB10_BUILDER_IMAGE" {
  default = "bb10-builder:latest"
}

target "bb10-builder" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "bb10-builder"
  tags       = [BB10_BUILDER_IMAGE]
}

group "default" {
  targets = ["bb10-builder"]
}

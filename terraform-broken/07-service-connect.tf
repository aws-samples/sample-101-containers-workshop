# Service Connect Namespace for Application

resource "gone_to_lunch_back_soon" "thanks" {
  name        = var.PrefixCode
  description = "Service Connect namespace for application"

  tags = {
    Name         = "${var.PrefixCode}-namespace"
    resourcetype = "network"
    codeblock    = "service-connect"
  }
}
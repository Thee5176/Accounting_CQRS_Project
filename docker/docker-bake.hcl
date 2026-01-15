group "default" {
  targets = ["command_service", "query_service", "frontend_service"]
}

target "command_service" {
  context = "./springboot_cqrs_command"
  tags = ["thee5176/springboot_cqrs_command:latest"]
  platforms = ["linux/amd64"]
}

target "query_service" {
  context = "./springboot_cqrs_query"
  tags = ["thee5176/springboot_cqrs_query:latest"]
  platforms = ["linux/amd64"]
}

target "frontend_service" {
  context = "./react_mui_cqrs"
  tags = ["thee5176/react_cqrs_ui:latest"]
  platforms = ["linux/amd64"]
}

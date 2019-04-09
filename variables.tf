variable "enabled" {
  default = true
  description = "Whether to start/stop the server"
}

variable "env" {
  description ="The environment variables generated by jupyterhub.Spawner::get_env.https://jupyterhub.readthedocs.io/en/stable/api/spawner.html#jupyterhub.spawner.Spawner.get_env"
  type = "map"
}
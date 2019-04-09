data "triton_image" "base" {
  name    = "centos-7"
  version = "20170327"
}

//
// Convert map(k,v) to string list [k1='v1',...,kn='vn']
locals {
  env_override = {
    PATH = "/bin:/usr/bin:/sbin:/usr/sbin",
  }
  merged_env = "${merge(var.env, local.env_override)}"
  env_keys = "${keys(local.merged_env)}"
}
data "template_file" "environment" {
  count = "${length(local.env_keys)}"
  template = "$${key}=\"$${value}\""
  vars = {
    key = "${local.env_keys[count.index]}"
    value = "${lookup(local.merged_env, local.env_keys[count.index])}"
  }
}


data "template_file" "cloud_config" {
  template = "${file("${path.module}/templates/cloud-init.yaml")}"
  vars = {
    ip = "0.0.0.0"
    port = "${local.jupyter_port}"
    environment_b64 = "${base64encode(join("\n",data.template_file.environment.*.rendered))}"

    user = "${local.merged_env["JUPYTERHUB_USER"]}"
  }
}

resource "triton_machine" "self" {
  name    = "${local.merged_env["JUPYTERHUB_CLIENT_ID"]}"
  package = "sample-2G"
  image   = "${data.triton_image.base.id}"

  root_authorized_keys = "${file("~/.ssh/id_rsa.pub")}"

  // Enable cloud-init
  // This is needed because Triton only enables cloud-init in the Ubuntu Certified images
  user_script = <<EOU
#!/usr/bin/env bash
if [ ! -e /root/sdc-cloud-init ]; then
  touch /root/sdc-cloud-init
  yum install --quiet --assumeyes cloud-init
  systemctl enable cloud-config
  systemctl enable cloud-final
  systemctl disable firewalld
  reboot
fi
EOU

  cloud_config = "${data.template_file.cloud_config.rendered}"
}

locals {
  jupyter_ip = "${triton_machine.self.primaryip}"
  jupyter_port = 8888
  jupyter_state = ""
}

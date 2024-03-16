#### variables para despliegue de repositorio
variable "location" {
  default = "Sweden Central"
}

variable "resource_group_name" {
  default = "grupo_recursos"
}

#### variables creacion maquina virtual
variable "vm_name" {
  default = "vm_ubuntu"
}

variable "admin_username" {
  default = "ubuntu"
}

variable "admin_password" {
  default = "123qweQWE"
}

variable "resource_group_name_prefix" {
  type    = string
  default = "prefix_example"
}

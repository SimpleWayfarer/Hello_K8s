variable "folder_id" {
  description = "(Optional) - Yandex Cloud Folder ID where resources will be created."
  type        = string
}

variable "k8s_version"{
  type = string
  default  = "1.30"
}

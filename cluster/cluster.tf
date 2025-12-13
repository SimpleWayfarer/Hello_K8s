#Создание кластера
resource "yandex_kubernetes_cluster" "k8s-cluster" {
  name        = "k8s-cluster"
  description = "k8s-cluster"

  network_id = yandex_vpc_network.my-ha-net.id

  master {
    version = var.k8s_version
    zonal {
      zone      = yandex_vpc_subnet.my-ha-subnet.zone
      subnet_id = yandex_vpc_subnet.my-ha-subnet.id
    }

    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "15:00"
        duration   = "3h"
      }
    }

    scale_policy {
      auto_scale {
        min_resource_preset_id = "s-c4-m16"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.ha-k8s-account.id
  node_service_account_id = yandex_iam_service_account.ha-k8s-account.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s-clusters-agent,
    yandex_resourcemanager_folder_iam_member.vpc-public-admin,
    yandex_resourcemanager_folder_iam_member.images-puller,
    yandex_resourcemanager_folder_iam_member.load-balancer-admin
  ]

}

#Создание сети и подсети
resource "yandex_vpc_network" "my-ha-net" {
  name = "my-ha-net"
}
resource "yandex_vpc_subnet" "my-ha-subnet" {
  name = "my-ha-subnet"
  v4_cidr_blocks = ["10.5.0.0/16"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.my-ha-net.id
}

#Создание сервисного аккаунта с нужными ролями
resource "yandex_iam_service_account" "ha-k8s-account" {
  name        = "ha-k8s-account"
  description = "Service account for the highly available Kubernetes cluster"
}
resource "yandex_resourcemanager_folder_iam_member" "k8s-clusters-agent" {
  # Сервисному аккаунту назначается роль "k8s.clusters.agent".
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.ha-k8s-account.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
  # Сервисному аккаунту назначается роль "vpc.publicAdmin".
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.ha-k8s-account.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
  # Сервисному аккаунту назначается роль "container-registry.images.puller".
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.ha-k8s-account.id}"
}
resource "yandex_resourcemanager_folder_iam_member" "load-balancer-admin" {
  # Сервисному аккаунту назначается роль "load-balancer.admin".
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s-cluster-account.id}"
}

#Создание группы узлов
resource "yandex_kubernetes_node_group" "k8s-ng" {
  name        = "k8s-ng"
  description = "k8s node group"
  cluster_id  = yandex_kubernetes_cluster.k8s-cluster.id
  version     = var.k8s_version
  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.my-ha-subnet.id}"]
    }

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }
  
  allocation_policy {
    location {
      zone      = yandex_vpc_subnet.my-ha-subnet.zone
    }
  }
  scale_policy {
    fixed_scale {
      size = 1
    }
  }
  deploy_policy {
    max_expansion   = 3
    max_unavailable = 1
  }
  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
    maintenance_window {
      start_time = "22:00"
      duration   = "10h"
    }
  }
}

#вывод id кластера
output "cluster_id" {
  value  = yandex_kubernetes_cluster.k8s-cluster.id
}

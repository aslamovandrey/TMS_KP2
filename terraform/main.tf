# main.tf

# Создание группы безопасности
resource "yandex_vpc_security_group" "devops-sg" {
  name        = "devops-sg"
  description = "Security group for DevOps VM"
  network_id  = data.yandex_vpc_network.default.id

  # Правило для SSH
  ingress {
    protocol    = "TCP"
    description = "SSH"
    port        = 22
    v4_cidr_blocks = ["0.0.0.0/0"] # В учебных целях открываем всем. В проде - ограничить по IP.
  }

  # Правило для приложения
  ingress {
    protocol    = "TCP"
    description = "App"
    port        = 5000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Правило для Jenkins
  ingress {
    protocol    = "TCP"
    description = "Jenkins"
    port        = 8080
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Разрешаем весь исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "Allow all egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Создание сети (сеть уже есть)
data "yandex_vpc_network" "default" {
  name = "default"
}

# Создание подсети
resource "yandex_vpc_subnet" "default" {
  name           = "devops-subnet"
  zone           = "ru-central1-a"
  network_id     = data.yandex_vpc_network.default.id
  v4_cidr_blocks = ["192.168.10.0/24"] # Внутренний диапазон IP
}

# Создание виртуальной машины
resource "yandex_compute_instance" "devops-vm" {
  name        = "devops-vm"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4 # Для комфортной работы Jenkins и приложения
  }

  boot_disk {
    initialize_params {
      image_id = "fd8cdbtd9eepnmm4gpne" # Ubuntu 22.04 LTS (актуальный ID можно найти в CLI)
      size     = 20
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.default.id
    security_group_ids = [yandex_vpc_security_group.devops-sg.id]
    nat                = true # Публичный IP
  }

  # Метаданные для SSH-доступа
  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: andrew
          groups: sudo
          shell: /bin/bash
          sudo: 'ALL=(ALL) NOPASSWD:ALL'
          ssh_authorized_keys:
            - "${file("~/.ssh/id_rsa.pub")}"  # Путь к публичному ключу
    EOF
  }
}

# --- Вывод внешнего IP ---
output "external_ip" {
  value = yandex_compute_instance.devops-vm.network_interface.0.nat_ip_address
}
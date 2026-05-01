terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone                     = "ru-central1-a" # Зона доступности по умолчанию
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = var.sa_key_file
}

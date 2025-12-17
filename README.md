Данный пример создает с помощью Terraform кластер Kubernetes в Yandex Cloud и запускает на нем приложение hello вместе с сервисом балансировщиком нагрузки

# Установка компонентов 
1) [Установка и инициализация интерфейса командной строки Yandex Cloud](https://yandex.cloud/ru/docs/cli/quickstart)
2) [Установка Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
3) [Установка kubectl](https://kubernetes.io/ru/docs/tasks/tools/install-kubectl/)

# Создание кластера
1) Создать файл terraform.tfvars со значениями переменных folder_id (идентификатор папки в облаке) и k8s_version (версия k8s, версия 1.30 по умолчанию скоро окончательно устареет)
2) Сделать файл create.sh исполняемым
```
chmod +x create.sh
```
3) Запустить файл create.sh
```
./create.sh
```
4) В файл output.txt запишется информация о приложение, IP-адрес для доступа находится в строке LoadBalancer Ingress

# Удаление кластера
1) Сделать файл destroy.sh исполняемым командой 
```
chmod +x ./destroy.sh
```
2) Запустить файл destroy.sh
```
./destroy.sh
```

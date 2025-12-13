#!/bin/bash

cd cluster
#эскпорт переменных в Terraform для работы с Yandex Cloud
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)

#Запуск Terraform и создание кластера
terraform init
terraform plan
echo 'yes' | terraform apply

#Пауза для ожидания завершения создания
sleep 60

#Получение id кластера и добавление учетных данных кластера
cluster_id=$(terraform output | cut -d '"' -f 2)
cd ../application
yc managed-kubernetes cluster get-credentials --id $cluster_id --external --force

#Создание namespace
kubectl create ns application
kubectl config set-context --current --namespace=application

#Деплой приложения hello и создание сервиса балансировщика нагрузки
kubectl apply -f deployment.yaml
kubectl apply -f load-balancer.yaml

#Пауза для ожидания запуска Ingress
sleep 120

#Вывод информации о приложениии
kubectl -n application describe svc hello > output.txt

#! /bin/bash

source variables

helm uninstall

kubectl delete secret $SECRET_NAME
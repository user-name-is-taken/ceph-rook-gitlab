#! /bin/bash
source ./variables
helm uninstall $RELEASE_NAME

kubectl delete secret $SECRET_NAME --namespace=$NAMESPACE
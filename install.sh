#! /bin/bash

# install s3 objects without installing gitlab 
# https://stackoverflow.com/questions/54032974/helm-conditionally-install-subchart
helm install --set gitlab.enabled=false

#set secret
export AWS_HOST=$(kubectl -n default get cm ceph-bucket -o yaml | grep BUCKET_HOST | awk '{print $2}')
export AWS_ACCESS_KEY_ID=$(kubectl -n default get secret ceph-bucket -o yaml | grep AWS_ACCESS_KEY_ID | awk '{print $2}' | base64 --decode)
export AWS_SECRET_ACCESS_KEY=$(kubectl -n default get secret ceph-bucket -o yaml | grep AWS_SECRET_ACCESS_KEY | awk '{print $2}' | base64 --decode)
export BUCKET_NAME=$(kubectl describe obc ceph-bucket | grep "^ *Bucket Name:" | sed 's/^ *Bucket Name: *//g')


# install gitlab without recreating s3 objects.
helm install --no-hooks 
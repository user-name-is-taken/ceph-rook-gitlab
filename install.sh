#! /bin/bash

source ./variables

# note you can also do this with helm install's 

echo "running helm install"
# install s3 objects without installing gitlab 
# https://stackoverflow.com/questions/54032974/helm-conditionally-install-subchart
helm install $RELEASE_NAME . --set gitlab.enabled=false --namespace=$NAMESPACE --dependency-update --atomic --debug

# get secret
export bucketName=$( helm show values . --skip-headers | grep "^ *bucket:" | head -1 | awk '{print $2}' ) 
export AWS_HOST=$(kubectl -n $NAMESPACE get cm $bucketName -o yaml | grep BUCKET_HOST | awk '{print $2}') 

# TODO: get the auto-generated secret name and replace "ceph-bucket" with it.
export AWS_ACCESS_KEY_ID=$(kubectl -n $NAMESPACE get secret ceph-bucket -o yaml | grep AccessKey | awk '{print $2}' | base64 --decode) 
export AWS_SECRET_ACCESS_KEY=$(kubectl -n $NAMESPACE get secret ceph-bucket -o yaml | grep SecretKey | awk '{print $2}' | base64 --decode)

# set secret
    # example: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.s3.yaml
    # docs: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/charts/globals.md#connection
    # more docs: https://docs.gitlab.com/ee/administration/job_artifacts.html#s3-compatible-connection-settings

# install gitlab without recreating s3 objects.

# TODO set variables: bucket,  
  # https://stackoverflow.com/questions/49928819/how-to-pull-environment-variables-with-helm-charts
helm install $RELEASE_NAME . --no-hooks --namespace=$NAMESPACE --set rook.aws_host=$AWS_HOST --set rook.aws_secret_access_key=$AWS_SECRET_ACCESS_KEY --set rook.aws_access_key_id=$AWS_ACCESS_KEY_ID
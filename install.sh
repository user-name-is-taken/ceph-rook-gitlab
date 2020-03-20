#! /bin/bash

#TODO replace this script with an init container https://gitlab.com/gitlab-org/charts/gitlab/issues/1920

source ./variables


# note you can also do this with helm install's 

echo "running helm install"
# install s3 objects without installing gitlab 
# https://stackoverflow.com/questions/54032974/helm-conditionally-install-subchart
#helm install $RELEASE_NAME . --set gitlab.enabled=false --namespace=$NAMESPACE --dependency-update --atomic

# set secret
    # example: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.s3.yaml
    # docs: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/charts/globals.md#connection
    # more docs: https://docs.gitlab.com/ee/administration/job_artifacts.html#s3-compatible-connection-settings
  

# install gitlab without recreating s3 objects.


######################REWRITE######################

command="helm install ${RELEASE_NAME} ."

# for loop: LFS, Artifacts, Uploads, Packages, and External MR diffs
  # get expected secret name from helm chart
  # get actual secrets from rook bucket secret
    # https://rook.github.io/docs/rook/v1.2/ceph-object.html
  # create secrets for helmchart from bucket secrets (using pipe)
    # https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/charts/globals.md#lfs-artifacts-uploads-packages-and-external-mr-diffs
    # https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.s3.yaml

# from rook.bucket
buckets=( lfs artifacts uploads packages externalDiffs pseudonymizer backups )

#  omniauth_bucket -> tmp_bucket?

for i in "${buckets[@]}"
do
  tmpfile=mktemp
  # get secret
  bucketName=$( helm show values . --skip-headers | grep "^ *${i}_bucket:" | head -1 | awk '{print $3}' ) 
  export AWS_HOST=$(kubectl -n $NAMESPACE get cm $bucketName -o yaml | grep BUCKET_HOST | awk '{print $2}') 

  # TODO: get the auto-generated secret name and replace "ceph-bucket" with it.
  export AWS_ACCESS_KEY_ID=$(kubectl -n $NAMESPACE get secret $bucketName -o yaml | grep AWS_ACCESS_KEY_ID: | awk '{print $2}' | base64 --decode) 
  export AWS_SECRET_ACCESS_KEY=$(kubectl -n $NAMESPACE get secret $bucketName -o yaml | grep AWS_SECRET_ACCESS_KEY: | awk '{print $2}' | base64 --decode)

  envsubst < s3base.txt > $tmpfile

  kubectl create secret generic "${bucketName}-bucket" --from-file=connection=$tmpfile

  command+=" --set gitlab.global.appConfig.${i}.connection.secret=${bucketName}-bucket --set gitlab.global.appConfig.${i}.connection.key=connection"

  rm $tmpfile

done

##### Get the s3cfg for backups...
#https://docs.gitlab.com/charts/advanced/external-object-storage/index.html
#https://rook.github.io/docs/rook/v1.2/ceph-object.html
# https://lollyrock.com/posts/s3cmd-with-radosgw/



s3cmd ls

command+="--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.task-runner.backups.objectStorage.config.secret=storage-config
--set gitlab.task-runner.backups.objectStorage.config.key=config"


eval $command

# set backup secret

# TODO set variables: bucket,  
  # https://stackoverflow.com/questions/49928819/how-to-pull-environment-variables-with-helm-charts
# helm install $RELEASE_NAME . --no-hooks --namespace=$NAMESPACE --set rook.aws_host=$AWS_HOST --set rook.aws_secret_access_key=$AWS_SECRET_ACCESS_KEY --set rook.aws_access_key_id=$AWS_ACCESS_KEY_ID
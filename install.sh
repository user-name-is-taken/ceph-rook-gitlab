#! /bin/bash

#TODO replace this script with an init container https://gitlab.com/gitlab-org/charts/gitlab/issues/1920

source ./variables


# note you can also do this with helm install's 

# install s3 objects without installing gitlab 
# https://stackoverflow.com/questions/54032974/helm-conditionally-install-subchart
helm install $RELEASE_NAME . --set gitlab.enabled=false --namespace=$NAMESPACE --dependency-update --atomic

# set secret
    # example: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.s3.yaml
    # docs: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/charts/globals.md#connection
    # more docs: https://docs.gitlab.com/ee/administration/job_artifacts.html#s3-compatible-connection-settings
  

# install gitlab without recreating s3 objects.


######################REWRITE######################

command="helm upgrade ${RELEASE_NAME} . --debug --no-hooks --reuse-values --set gitlab.enabled=true "

# for loop: LFS, Artifacts, Uploads, Packages, and External MR diffs
  # get expected secret name from helm chart
  # get actual secrets from rook bucket secret
    # https://rook.github.io/docs/rook/v1.2/ceph-object.html
  # create secrets for helmchart from bucket secrets (using pipe)
    # https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/charts/globals.md#lfs-artifacts-uploads-packages-and-external-mr-diffs
    # https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.s3.yaml

# from rook.bucket
buckets=( lfs artifacts uploads packages externalDiffs pseudonymizer backups tmpBucket )

#  omniauth_bucket -> tmp_bucket?

# translates secrets from buckets created by helm to gitlab's format
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


  if [ $i = "backups" ] || [ $i = "tmpBucket" ]; then
    command+=" --set global.appConfig.backups.${i}=$bucketName"
  else
    kubectl create secret generic "${bucketName}-bucket" --from-file=connection=$tmpfile
    command+=" --set gitlab.global.appConfig.${i}.connection.secret=${bucketName}-bucket --set gitlab.global.appConfig.${i}.connection.key=connection"
  fi
  rm $tmpfile

done

##### Get the s3cfg for backups...
#https://docs.gitlab.com/charts/advanced/external-object-storage/index.html
#https://rook.github.io/docs/rook/v1.2/ceph-object.html
# https://lollyrock.com/posts/s3cmd-with-radosgw/


#user has to be in the same namespace as the store...????

export STORE_NAME=$( helm show values . --skip-headers | grep "^ *storename:" | head -1 | awk '{print $2}' ) 

tmpUserYaml=mktemp

envsubst < ./s3_secret_steps/s3-user.yaml > $tmpUserYaml

cat $tmpUserYaml

kubectl create -f $tmpUserYaml -n rook-ceph

## Note: git user is from s3-user.yaml
SECRET_NAME=rook-ceph-object-user-$STORE_NAME-my-user

sleep 10

export AWS_USER_ACCESS_KEY_ID=$(kubectl -n rook-ceph get secret $SECRET_NAME -o yaml | grep AccessKey: | awk '{print $2}' | base64 --decode) 
export AWS_USER_SECRET_ACCESS_KEY=$(kubectl -n rook-ceph get secret $SECRET_NAME -o yaml | grep SecretKey: | awk '{print $2}' | base64 --decode)

echo $AWS_USER_ACCESS_KEY_ID

echo $AWS_USER_SECRET_ACCESS_KEY
echo $AWS_HOST

# https://medium.com/flant-com/to-rook-in-kubernetes-df13465ff553

s3cmd --configure --dump-config --access_key=$AWS_USER_ACCESS_KEY_ID --secret_key=$AWS_USER_SECRET_ACCESS_KEY --no-ssl --host-bucket=rook-ceph-rgw-$STORE_NAME --host=rook-ceph-rgw-$STORE_NAME.rook-ceph --host-bucket=rook-ceph-rgw-$STORE_NAME.rook-ceph > $tmpUserYaml

#s3cmd ls --access_key=$AWS_USER_ACCESS_KEY_ID --secret_key=$AWS_USER_SECRET_ACCESS_KEY --no-ssl --host=10.97.157.239 --host-bucket=rook-ceph-rgw-$STORE_NAME

cat $tmpUserYaml

# TODO: use a hostname, not an ip address here


kubectl create secret generic storage-config --from-file=config=$tmpUserYaml

command+=" --set gitlab.gitlab.task-runner.backups.objectStorage.config.secret=storage-config --set gitlab.gitlab.task-runner.backups.objectStorage.config.key=config"

echo $command

eval $command


# set backup secret

# TODO set variables: bucket,  
  # https://stackoverflow.com/questions/49928819/how-to-pull-environment-variables-with-helm-charts
# helm install $RELEASE_NAME . --no-hooks --namespace=$NAMESPACE --set rook.aws_host=$AWS_HOST --set rook.aws_secret_access_key=$AWS_SECRET_ACCESS_KEY --set rook.aws_access_key_id=$AWS_ACCESS_KEY_ID
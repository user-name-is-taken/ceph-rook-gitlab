#! /bin/bash
source ./variables


helm uninstall $RELEASE_NAME

# kubectl delete secret $SECRET_NAME --namespace=$NAMESPACE

buckets=( lfs artifacts uploads packages externalDiffs pseudonymizer backups  tmpBucket )

for i in "${buckets[@]}"
do

  export bucketName=$( helm show values . --skip-headers | grep "^ *${i}_bucket:" | head -1 | awk '{print $3}' ) 
    
  kubectl delete secret "${bucketName}-bucket"
  # append to the helm install command... "--set ...bucket --set ...key"

done

export STORE_NAME=$( helm show values . --skip-headers | grep "^ *storename:" | head -1 | awk '{print $2}' ) 

tmpUserYaml=mktemp

envsubst < ./s3_secret_steps/s3-user.yaml > $tmpUserYaml

kubectl delete -f $tmpUserYaml -n rook-ceph

kubectl delete secret storage-config
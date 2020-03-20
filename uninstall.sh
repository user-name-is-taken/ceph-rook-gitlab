#! /bin/bash
source ./variables


helm uninstall $RELEASE_NAME

# kubectl delete secret $SECRET_NAME --namespace=$NAMESPACE

buckets=( lfs artifacts uploads packages externalDiffs pseudonymizer backups )

for i in "${buckets[@]}"
do

  export bucketName=$( helm show values . --skip-headers | grep "^ *${i}_bucket:" | head -1 | awk '{print $3}' ) 
    
  kubectl delete secret "${bucketName}-bucket"
  # append to the helm install command... "--set ...bucket --set ...key"

done
#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

dockerUser=$1
dockerPassword=$2
version=$3
outputDir=$4
accessToken=$5
refreshToken=$6
tokenEndpoint=$7
idToken=$8
expiration=$9
dryRun=${10}

sudo rm -rf ${outputDir}/*
sudo docker login nexus.onetrust.com:8443 -u ${dockerUser} -p ${dockerPassword}
sudo docker pull nexus.onetrust.com:8443/mobnativesdkflutter:${version}
sudo mkdir -p ${outputDir}
echo "Starting mobnativesdkflutter..."
sudo docker run --network=app_default --rm -t -v ${outputDir}:/mobnativesdkflutter/output --name mobnativesdkflutter -w /publishers-mobile-native-sdk-flutter/ nexus.onetrust.com:8443/mobnativesdkflutter:${version} python3 ./deploy/publish.py --access_token "${accessToken}" --refresh_token "${refreshToken}" --token_endpoint "${tokenEndpoint}" --id_token "${idToken}" --expiration "${expiration}" --dry_run "${dryRun}"
echo "Done."
sudo docker logout

exit 0

#!/bin/sh

set -o errexit

DIR=$(cd `dirname $0` && pwd)

#MIX_ENV=kube mix deps.get
#MIX_ENV=kube mix deps.compile
MIX_ENV=kube mix release

docker build -t tjheeta/ltse_poc ${DIR}/..
docker push tjheeta/ltse_poc:latest


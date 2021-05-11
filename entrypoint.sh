#!/bin/bash

mkdir -p /root/.docker/

cat << EOF >> /root/.docker/config.json
{
    "credsStore": "ecr-login",
    "credHelpers": {
        "ecr.${AWS_REGION}.amazonaws.com": "ecr-login"
    }
}
EOF

DOCKERFILE=${PLUGIN_DOCKERFILE:-Dockerfile}

OPTS="-f ${DOCKERFILE}"

CONTEXT=${PLUGIN_CONTEXT:-}
if [ "${CONTEXT}" ]; then
    CONTEXT="${PWD}/${CONTEXT}"
else
    CONTEXT="${PWD}"
fi

PLUGIN_REGISTRY=${PLUGIN_REGISTRY:-}
PLUGIN_APP_NAME=${PLUGIN_APP_NAME:-$(basename $DRONE_REMOTE_URL .git)}
PLUGIN_APP_IMAGE_PATH="${PLUGIN_APP_IMAGE_PATH:-$PLUGIN_REGISTRY/$PLUGIN_APP_NAME}"
PLUGIN_VERSION=${PLUGIN_VERSION:-${DRONE_COMMIT:0:7}}

if [[ "${PLUGIN_CACHE:-true}" == "true" ]]; then
    OPTS="${OPTS} --build-arg BUILDKIT_INLINE_CACHE=1"
else
    OPTS="${OPTS} --no-cache"
fi
if [[ "${PLUGIN_AUTO_TAG:-true}" == "true" ]]; then
   echo "latest,${PLUGIN_VERSION}" > .tags
fi

if [ -n "${PLUGIN_TAGS:-}" ]; then
    TAGS=$(echo "${PLUGIN_TAGS}" | tr ',' '\n' | while read tag; do echo "-t ${PLUGIN_APP_IMAGE_PATH}:${tag} "; done)
    PUSHES=$(echo "${PLUGIN_TAGS}" | tr ',' '\n' | while read tag; do echo "${PLUGIN_APP_IMAGE_PATH}:${tag}\n"; done)
    echo "${PLUGIN_TAGS}" | tr ',' '\n' | while read tag; do echo "${PLUGIN_APP_IMAGE_PATH}:${tag} "; done
elif [ -f .tags ]; then
    TAGS=$(cat .tags| tr ',' '\n' | while read tag; do echo "-t ${PLUGIN_APP_IMAGE_PATH}:${tag} "; done)
    PUSHES=$(cat .tags| tr ',' '\n' | while read tag; do echo "${PLUGIN_APP_IMAGE_PATH}:${tag}\n"; done)
    cat .tags| tr ',' '\n' | while read tag; do echo "${PLUGIN_APP_IMAGE_PATH}:${tag} "; done
else
    TAGS="-t ${PLUGIN_APP_IMAGE_PATH}:latest"
    PUSHES="${PLUGIN_APP_IMAGE_PATH}:latest\n"
    echo ${PLUGIN_APP_IMAGE_PATH}:latest
fi
OPTS="${OPTS} ${TAGS} ${CONTEXT}"
eval docker build ${OPTS}
if [[ "${PLUGIN_PUSH:-true}" == "true" ]]; then
    echo -e $PUSHES | xargs -n 1 docker push
fi


#!/bin/bash
#
#

DEPLOY_DIR=/volume1/maintenance/docker/calibre
RELEASE_DIR=/volume1/maintenance/docker/calibre/releases
RELEASE_ARTEFACT=@@@ARTEFACT_NAME@@@

if [ -d ${RELEASE_DIR}/build ]
then
    echo "remove existing build directory"
    rm -rf ${RELEASE_DIR}/build/*
    echo "remove done"
fi

if [ -f ${RELEASE_DIR}/${RELEASE_ARTEFACT}.tar.gz ]
then
    echo "decompress artefact"
    tar -xf ${RELEASE_DIR}/${RELEASE_ARTEFACT}.tar.gz -C ${RELEASE_DIR}
    echo "decompress done"
fi

if [ -f ${RELEASE_DIR}/build/version ]
then
  cp -fv ${RELEASE_DIR}/build/version ${DEPLOY_DIR}/version
  cp -fv ${RELEASE_DIR}/build/target/recipes/* ${DEPLOY_DIR}/target/recipes 
  cp -fv ${RELEASE_DIR}/build/cronjob/cron.news.sh ${DEPLOY_DIR}/cronjob/cron.news.sh
  cp -fv ${RELEASE_DIR}/build/cronjob/action.news/scripts/*.sh ${DEPLOY_DIR}/cronjob/action.news/scripts
  echo ""
  echo "release deployed successful on remote"
  cat ${DEPLOY_DIR}/version
  echo ""
  echo ""
fi

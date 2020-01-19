#!/bin/sh
#
# weekly cron job action script
#

WOY=`date +%V`    # Week of the Year (0-53)
NOW=`date +%w`    # Number of the weekday 0 for Sunday
WDN=`date +%a`    # locals abbre weekday name

ACTIONS="/volume1/maintenance/action.news"

for EACH_ACTION in ${ACTIONS}/${WDN}-*.sh
do
  if [ -d ${EACH_ACTION} ]
  then
    echo "[ACTION.NEWS] File ${EACH_ACTION} is not a shell script"
    continue
  fi

  if [ -x ${EACH_ACTION} ]
  then
    echo -n "[ACTION.NEWS] Execute news shell script: ${EACH_ACTION}"
    $EACH_ACTION
  fi

done

#EOF

#!/bin/bash
if [[ ${SSHD} == true ]]
then
    sed -i 's|\(autostart = \)false|\1true|' /opt/supervisor/sshd.conf
fi
chown -R 1000 "$JENKINS_HOME"
/bin/tini -- /usr/bin/supervisord

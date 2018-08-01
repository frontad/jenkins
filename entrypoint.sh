#!/bin/bash
if [[ ${SSHD} == true ]]
then
    sed -i 's|\(autostart = \)false|\1true|' /opt/supervisor/sshd.conf
fi
/bin/tini -- /usr/bin/supervisord

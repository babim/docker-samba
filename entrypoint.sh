#!/bin/sh

# value
USER1=${USER:-samba}
WORKGROUP=${WORKGROUP:-WORKGROUP}
HOSTNAME=$(hostname -s)
PASS=${PASS:-samba}

if [ ! -D "/share/data" ]; then mkdir -p /share/data; fi

# add a non-root user and group called "samba" with no password, no home dir, no shell, and gid/uid set to 1000
RUN addgroup -g 1000 $USER1 && adduser -D -H -G $USER1 -s /bin/false -u 1000 $USER1

# create a samba user matching our user from above with a very simple password ("samba")
RUN echo -e "$PASS\n$PASS" | smbpasswd -a -s -c /config/smb.conf $USER1

# set config
if [ ! -f "/config/smb.conf" ]; then
cat <<EOF>> /config/smb.conf
[global]
    netbios name = $HOSTNAME
    workgroup = $WORKGROUP
    server string = Samba %v in an Alpine Linux Docker container
    security = user
    guest account = nobody
    map to guest = Bad User

    # disable printing services
    load printers = no
    printing = bsd
    printcap name = /dev/null
    disable spoolss = yes

[data]
    comment = Data
    path = /share/data
    read only = yes
    write list = $USER1
    guest ok = yes
    # getting rid of those annoying .DS_Store files created by Mac users...
    veto files = /._*/.DS_Store/
    delete veto files = yes
EOF

if [[ ! -z "${USER}" ]]; then
if [ ! -D "/share/private" ]; then mkdir -p /share/private; fi
cat <<EOF>> /config/smb.conf
[private]
    comment = Data private
    path = /share/private
    writeable = yes
    valid users = babim
    # getting rid of those annoying .DS_Store files created by Mac users...
    veto files = /._*/.DS_Store/
    delete veto files = yes
EOF
fi

fi
exec "$@"

**Application**

[Preclear](https://forums.unraid.net/topic/2732-preclear_disksh-a-new-utility-to-burn-in-and-pre-clear-disks-for-quick-add/)

**Description**

A utility to "burn-in" a new disk, before adding it to your array has been requested several times.  Also requested is a process to "pre-clear" a hard disk before adding it to your array.  When a special "signature" is detected, the lengthy "clearing" step otherwise performed by unRAID is skipped.

The Preclear script was created by [Joe L.](https://forums.unraid.net/topic/2732-preclear_disksh-a-new-utility-to-burn-in-and-pre-clear-disks-for-quick-add/) and later modified by [bjp999](https://forums.unraid.net/topic/30921-unofficial-faster-preclear/), all credit goes to both of these authors for the script.

**Build notes**

IMPORTANT - This is Docker image is specifically for unRAID users ONLY - do NOT attempt to use this utility with other operating systems.

**Usage**
```
docker run -d \
    -p 5900:5900 \
    -p 6080:6080 \
    --name=<container name> \
    --privileged=true \
    -v /boot/config/disk.cfg:/unraid/config/disk.cfg:ro \
    -v /boot/config/super.dat:/unraid/config/super.dat:ro \
    -v /var/local/emhttp/disks.ini:/unraid/emhttp/disks.ini:ro \
    -v /usr/local/sbin/mdcmd:/unraid/mdcmd:ro \
    -v /dev/disk/by-id:/unraid/disk/by-id:ro \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e WEBPAGE_TITLE=<name shown in browser tab> \
    -e VNC_PASSWORD=<password for web ui> \
    -e UMASK=<umask for created files> \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-preclear
```

Please replace all user variables in the above command defined by <> with the correct values.

**Example**
```
docker run -d \
    -p 5900:5900 \
    -p 6080:6080 \
    --name=preclear \
    --privileged=true \
    -v /boot/config/disk.cfg:/unraid/config/disk.cfg:ro \
    -v /boot/config/super.dat:/unraid/config/super.dat:ro \
    -v /var/local/emhttp/disks.ini:/unraid/emhttp/disks.ini:ro \
    -v /usr/local/sbin/mdcmd:/unraid/mdcmd:ro \
    -v /dev/disk/by-id:/unraid/disk/by-id:ro \
    -v /apps/docker/preclear:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e WEBPAGE_TITLE=Preclear \
    -e VNC_PASSWORD=mypassword \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-preclear
```

If you do specify a password for the web ui via the env var 'VNC_PASSWORD' then it MUST be 6 characters or longer, otherwise it will be ignored.

**Access via web interface (noVNC)**

`http://<host ip>:<host port>/vnc.html?resize=remote&host=<host ip>&port=<host port>&&autoconnect=1`

e.g.:-

`http://192.168.1.10:6080/vnc.html?resize=remote&host=192.168.1.10&port=6080&&autoconnect=1`

**Access via VNC client**

`<host ip>::<host port>`

e.g.:-

`192.168.1.10::5900`

**Notes**

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

```
id <username>
```
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.net/topic/81397-support-binhex-preclear/)
#!/bin/bash

# exit script if return code != 0
set -e

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /usr/local/bin/

# pacman packages
####

# define pacman packages
pacman_packages="smartmontools parted s-nail"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages="ssmtp"

# call aur install script (arch user repo)
source aur.sh

# custom
####

# download preclear script - this is the modified 'faster' bjp version with additional tweaks to make it docker friendly
curly.sh -rc 6 -rw 10 -of "/usr/local/bin/preclear_binhex.sh" -url "https://raw.githubusercontent.com/binhex/scripts/master/shell/unraid/system/preclear/binhex/preclear_binhex.sh"

# mark script as executable
chmod +x "/usr/local/bin/preclear_binhex.sh"

# download readvz (64 bit) utility - referenced by preclear script
curly.sh -rc 6 -rw 10 -of "/usr/local/bin/readvz" -url "https://raw.githubusercontent.com/binhex/scripts/master/shell/unraid/system/preclear/binhex/readvz"

# mark readvz as executable
chmod +x "/usr/local/bin/readvz"

# delete default ssmtp.conf, as we copy across the unraid configured file
rm -f '/etc/ssmtp/ssmtp.conf'

# config novnc
###

# overwrite novnc 16x16 icon with application specific 16x16 icon (used by bookmarks and favorites)
cp /home/nobody/novnc-16x16.png /usr/share/webapps/novnc/app/images/icons/

cat <<'EOF' > /tmp/startcmd_heredoc
# launch xfce4-terminal (we cannot simply call /usr/bin/xfce4-terminal otherwise it wont run on startup)
# note failure to launch xfce4-terminal in the below manner will result in the classic xcb missing error
dbus-run-session -- xfce4-terminal
EOF

# replace startcmd placeholder string with contents of file (here doc)
sed -i '/# STARTCMD_PLACEHOLDER/{
	s/# STARTCMD_PLACEHOLDER//g
	r /tmp/startcmd_heredoc
}' /home/nobody/start.sh
rm /tmp/startcmd_heredoc

# container perms
####

# define comma separated list of paths
install_paths="/tmp,/usr/share/themes,/home/nobody,/usr/share/webapps/novnc,/usr/share/applications,/etc/xdg"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# create file with contents of here doc, note EOF is NOT quoted to allow us to expand current variable 'install_paths'
# we use escaping to prevent variable expansion for PUID and PGID, as we want these expanded at runtime of init.sh
cat <<EOF > /tmp/permissions_heredoc

# get previous puid/pgid (if first run then will be empty string)
previous_puid=\$(cat "/root/puid" 2>/dev/null || true)
previous_pgid=\$(cat "/root/pgid" 2>/dev/null || true)

# if first run (no puid or pgid files in /tmp) or the PUID or PGID env vars are different
# from the previous run then re-apply chown with current PUID and PGID values.
if [[ ! -f "/root/puid" || ! -f "/root/pgid" || "\${previous_puid}" != "\${PUID}" || "\${previous_pgid}" != "\${PGID}" ]]; then

	# set permissions inside container - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
	chown -R "\${PUID}":"\${PGID}" ${install_paths}

fi

# write out current PUID and PGID to files in /root (used to compare on next run)
echo "\${PUID}" > /root/puid
echo "\${PGID}" > /root/pgid

# env var required to find qt plugins when starting hexchat
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/qt/plugins/platforms

# env vars required to enable menu icons for hexchat (also requires breeze-icons package)
export KDE_SESSION_VERSION=5 KDE_FULL_SESSION=true

if [ -f '/unraid/ssmtp/ssmtp.conf' ]; then

	# copy unraid ssmtp config file (used by dynamix notification) from the host to the volume mount and
	# we then add in path to CA trusted certs bundle for arch linux
	if [ ! -f '/config/ssmtp/ssmtp.conf' ]; then
		echo "[info] copying unraid mail config file '/unraid/ssmtp/ssmtp.conf' to '/config/ssmtp/ssmtp.conf'..." | ts '%Y-%m-%d %H:%M:%.S'
		mkdir -p /config/ssmtp && cp '/unraid/ssmtp/ssmtp.conf' '/config/ssmtp/ssmtp.conf'
		echo 'TLS_CA_FILE=/etc/ca-certificates/extracted/ca-bundle.trust.crt' >> '/config/ssmtp/ssmtp.conf'
	fi

	# softlink ssmtp config file back to location expected by ssmtp
	if [ ! -f '/etc/ssmtp/ssmtp.conf' ]; then
		echo "[info] creating softlink from copied unraid mail config file '/config/ssmtp/ssmtp.conf' to '/etc/ssmtp/ssmtp.conf'..." | ts '%Y-%m-%d %H:%M:%.S'
		mkdir -p /etc/ssmtp && ln -s '/config/ssmtp/ssmtp.conf' '/etc/ssmtp/ssmtp.conf'
	fi

	chmod 600 '/config/ssmtp/ssmtp.conf'

else

	echo "[warn] container is missing required volume mount for mail config '/unraid/ssmtp/ssmtp.conf'" | ts '%Y-%m-%d %H:%M:%.S'

fi
EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
	s/# PERMISSIONS_PLACEHOLDER//g
	r /tmp/permissions_heredoc
}' /usr/local/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

# cleanup
cleanup.sh

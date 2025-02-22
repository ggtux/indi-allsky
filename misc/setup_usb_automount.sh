#!/bin/bash

#set -x  # command tracing
set -o errexit
set -o nounset


PATH=/bin:/usr/bin
export PATH


DISTRO_NAME=$(lsb_release -s -i)
DISTRO_RELEASE=$(lsb_release -s -r)
CPU_ARCH=$(uname -m)


echo
echo "#######################################################"
echo "### Welcome to the indi-allsky USB automount script ###"
echo "#######################################################"

if [[ "$(id -u)" == "0" ]]; then
    echo "Please do not run this script as root"
    echo "Re-run this script as the user which will execute the indi-allsky software"
    echo
    echo
    exit 1
fi


if [[ -f "/etc/astroberry.version" ]]; then
    echo "Please do not run this script on an Astroberry server"
    echo "Astroberry has native automount support"
    echo
    echo
    exit 1
fi


echo
echo
echo "This script sets up USB automount (udisks2) for your Allsky camera"
echo
echo
echo "Distribution: $DISTRO_NAME"
echo "Release: $DISTRO_RELEASE"
echo "Arch: $CPU_ARCH"
echo
echo
echo


echo "Setup proceeding in 10 seconds... (control-c to cancel)"
echo
sleep 10


# Run sudo to ask for initial password
sudo true


echo "**** Installing packages... ****"
if [[ "$DISTRO_NAME" == "Raspbian" && "$DISTRO_RELEASE" == "11" ]]; then

    sudo apt-get update
    sudo apt-get -y install \
        udisks2 \
        udiskie \
        exfatprogs \
        dosfstools

elif [[ "$DISTRO_NAME" == "Raspbian" && "$DISTRO_RELEASE" == "10" ]]; then

    sudo apt-get update
    sudo apt-get -y install \
        udisks2 \
        udiskie \
        exfat-utils \
        dosfstools

elif [[ "$DISTRO_NAME" == "Debian" && "$DISTRO_RELEASE" == "11" ]]; then

    sudo apt-get update
    sudo apt-get -y install \
        udisks2 \
        udiskie \
        exfatprogs \
        dosfstools

elif [[ "$DISTRO_NAME" == "Debian" && "$DISTRO_RELEASE" == "10" ]]; then

    sudo apt-get update
    sudo apt-get -y install \
        udisks2 \
        udiskie \
        exfat-utils \
        dosfstools

elif [[ "$DISTRO_NAME" == "Ubuntu" && "$DISTRO_RELEASE" == "22.04" ]]; then

    sudo apt-get update
    sudo apt-get -y install \
        udisks2 \
        udiskie \
        exfatprogs \
        dosfstools

elif [[ "$DISTRO_NAME" == "Ubuntu" && "$DISTRO_RELEASE" == "20.04" ]]; then

    sudo apt-get update
    sudo apt-get -y install \
        udisks2 \
        udiskie \
        exfat-utils \
        dosfstools

elif [[ "$DISTRO_NAME" == "Ubuntu" && "$DISTRO_RELEASE" == "18.04" ]]; then

    sudo apt-get update
    sudo apt-get -y install \
        udisks2 \
        udiskie \
        exfat-utils \
        dosfstools

else
    echo "Unknown distribution $DISTRO_NAME $DISTRO_RELEASE ($CPU_ARCH)"
    exit 1
fi


# find script directory for service setup
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR/.."
ALLSKY_DIRECTORY=$PWD
cd "$OLDPWD"



echo "**** Setup policy kit permissions ****"
TMP8=$(mktemp)
sed \
 -e "s|%ALLSKY_USER%|$USER|g" \
 "${ALLSKY_DIRECTORY}/service/90-org.aaronwmorris.indi-allsky.pkla" > "$TMP8"

sudo cp -f "$TMP8" "/etc/polkit-1/localauthority/50-local.d/90-org.aaronwmorris.indi-allsky.pkla"
sudo chown root:root "/etc/polkit-1/localauthority/50-local.d/90-org.aaronwmorris.indi-allsky.pkla"
sudo chmod 644 "/etc/polkit-1/localauthority/50-local.d/90-org.aaronwmorris.indi-allsky.pkla"
[[ -f "$TMP8" ]] && rm -f "$TMP8"



# create users systemd folder
[[ ! -d "${HOME}/.config/systemd/user" ]] && mkdir -p "${HOME}/.config/systemd/user"


cp -f "${ALLSKY_DIRECTORY}/service/udiskie-automount.service" "${HOME}/.config/systemd/user/udiskie-automount.service"
chmod 644 "${HOME}/.config/systemd/user/udiskie-automount.service"


systemctl --user daemon-reload
systemctl --user enable udiskie-automount.service
systemctl --user start udiskie-automount.service


echo
echo "Please insert your USB media now"
echo
# shellcheck disable=SC2034
read -n1 -r -p "Press any key to continue..." anykey


# Allow web server access to mounted media
if [[ -d "/media/${USER}" ]]; then
    sudo chmod ugo+x "/media/${USER}"
else
    echo
    echo
    echo "Media not detected..."
    echo "You may need to run this script again once you insert your media"
    echo "for the correct access permissions for the web server"
    echo
fi


echo
echo
echo "USB automounting is now enabled... enjoy"
echo
echo



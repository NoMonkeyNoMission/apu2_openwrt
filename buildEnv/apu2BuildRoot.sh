#!/bin/bash
#
# apu2BuildRoot.sh
#
# Creates the build environment required to re-build my image for APU2 boards with at least 2 NICs
#

### Prerequisites for buildroot
sudo apt-get update
sudo apt install build-essential git libncurses5-dev gawk unzip wget curl zlib1g-dev python3-distutils


PS3='Please select your preferred OpenWRT release: '
options=("Snapshot" "18.06.8" "19.07.3" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Snapshot")
            echo "Using OpenWrt Snapshot"
            VERSION='snapshot'
            RELEASE='https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-imagebuilder-x86-64.Linux-x86_64.tar.xz'
            DIR='openwrt-imagebuilder-x86-64.Linux-x86_64'
            break
            ;;
       "18.06.9")
            echo "Using OpenWrt 18.06.9"
            VERSION='18.06'
            RELEASE='https://downloads.openwrt.org/releases/18.06.9/targets/x86/64/openwrt-imagebuilder-18.06.9-x86-64.Linux-x86_64.tar.xz'
            DIR='openwrt-imagebuilder-18.06.9-x86-64.Linux-x86_64'
            break
            ;;
        "19.07.6")
            echo "Using OpenWrt 19.07.6"
            VERSION='19.07'
            RELEASE='https://downloads.openwrt.org/releases/19.07.6/targets/x86/64/openwrt-imagebuilder-19.07.6-x86-64.Linux-x86_64.tar.xz'
            DIR='openwrt-imagebuilder-19.07.6-x86-64.Linux-x86_64'
            break
          ;;
        "Quit")
            exit 1
            ;;
        *) echo "invalid option $REPLY"
        	;;
    esac
done

### Get imagebuilder and cd there
echo "$RELEASE"
curl -L  "$RELEASE" | unxz | tar -xf -

cd "$DIR" || exit

### files dir (outside main directory to protect from make distclean)
mkdir -p files/etc/config
cp ../files/* files/etc/config/

### grab the banIP packages, handling the case where the files may not be present if Buildbot is working
UNBOUND='unbound-daemon'

if [ "$VERSION" = "18.06" ]
then

    UNBOUND='unbound'

    ### add repo to repositories.conf
    ! grep -q 'stangri_repo' repositories.conf && sed -i '2 i\src/gz stangri_repo repo.openwrt.melmac.net' repositories.conf

    wget -r -l1 -np -nd "https://downloads.openwrt.org/snapshots/packages/x86_64/packages/" -P ./packages/ -A "banip*.ipk"
    wget -r -l1 -np -nd "https://downloads.openwrt.org/snapshots/packages/x86_64/luci/" -P ./packages/ -A "luci-app-banip*.ipk"
    COUNT=$(ls -1q packages/*banip* | wc -l)

    if [ "$COUNT" -ne 2 ]
    then
        rm packages/*banip*
        cp ../packages/* packages/
    fi
fi

### make!
make clean
make image PACKAGES="luci -dnsmasq dnsmasq-full kmod-gpio-button-hotplug kmod-crypto-hw-ccp kmod-leds-apu2 kmod-leds-gpio kmod-sp5100_tco kmod-usb-ohci kmod-usb2 kmod-usb3 kmod-gpio-nct5104d kmod-pcspkr kmod-usb-core kmod-sound-core kmod-ipt-nat6 libustream-mbedtls fstrim irqbalance amd64-microcode flashrom adblock ipset resolveip ip-full kmod-ipt-ipset iptables luci-app-adblock luci-app-sqm luci-app-vpn-policy-routing luci-app-wireguard luci-proto-wireguard qrencode stubby $UNBOUND vpn-policy-routing luci-ssl curl wget tcpdump luci-app-wol 6in4 6to4 6rd luci-theme-bootstrap luci-theme-material usbutils usb-modeswitch kmod-usb-net-huawei-cdc-ncm kmod-usb-net-cdc-ncm kmod-usb-net-cdc-ether comgt-ncm kmod-usb-serial kmod-usb-serial-option kmod-usb-serial-wwan luci-proto-ncm luci-proto-3g banip luci-app-banip avahi-dbus-daemon avahi-utils" EXTRA_IMAGE_NAME="apu2_2nic_nomonkeynomission" FILES=files/

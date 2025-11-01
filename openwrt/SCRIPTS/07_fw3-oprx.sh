#!/bin/bash
# FW3
mkdir -p package/network/config/firewall/patches
cp -rf ../lede/package/network/config/firewall/patches/100-fullconenat.patch ./package/network/config/firewall/patches/100-fullconenat.patch
cp -rf ../lede/package/network/config/firewall/patches/101-bcm-fullconenat.patch ./package/network/config/firewall/patches/101-bcm-fullconenat.patch
# iptables
cp -rf ../lede/package/network/utils/iptables/patches/900-bcm-fullconenat.patch ./package/network/utils/iptables/patches/900-bcm-fullconenat.patch
# network  #net.netfilter.nf_conntrack_buckets
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
# luci滚回fw3：Patch LuCI 以增添 FullCone 开关  #luci-app-firewall_add_fullcone_fw3.patch
pushd feeds/luci
patch -Rp1 <../.././diydata/PATCH/pkgs/firewall/luci/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
wget -qO- https://github.com/openwrt/luci/commit/471182b2.patch | patch -p1
popd
# FullCone PKG  #来源lede immortalwrtde 要新，支持ipv6
#cp -rf ../lede/package/network/utils/fullconenat  ./package/network/utils/fullconenat
cp -rf ../immortalwrt_24/package/network/utils/fullconenat  ./package/network/utils/fullconenat

# 滚回fw3  上面已经回滚
#pushd feeds/luci
#patch -Rp1 <../.././diydata/PATCH/firewall/luci-app-firewall_add_fullcone_fw4.patch
#patch -p1 <../.././diydata/PATCH/firewall/luci-app-firewall_add_fullcone_fw3.patch
#popd

sed -i 's,iptables-nft,iptables-legacy,g' ./package/new/luci-app-passwall2/Makefile
sed -i 's,iptables-nft,iptables-legacy,g' ./package/helloworld/luci-app-passwall/Makefile
sed -i 's,iptables-nft +kmod-nft-fullcone,iptables-mod-fullconenat,g' ./package/new/addition-trans-zh/Makefile

#rm -rf ./feeds/packages/net/miniupnpd
#cp -rf ../immortalwrt_pkg_24/net/miniupnpd ./feeds/packages/net/miniupnpd
#wget https://github.com/miniupnp/miniupnp/commit/0e8c68d.patch -O feeds/packages/net/miniupnpd/patches/0e8c68d.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/0e8c68d.patch
#wget https://github.com/miniupnp/miniupnp/commit/21541fc.patch -O feeds/packages/net/miniupnpd/patches/21541fc.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/21541fc.patch
#wget https://github.com/miniupnp/miniupnp/commit/b78a363.patch -O feeds/packages/net/miniupnpd/patches/b78a363.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/b78a363.patch
#wget https://github.com/miniupnp/miniupnp/commit/8f2f392.patch -O feeds/packages/net/miniupnpd/patches/8f2f392.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/8f2f392.patch
#wget https://github.com/miniupnp/miniupnp/commit/60f5705.patch -O feeds/packages/net/miniupnpd/patches/60f5705.patch
#sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/60f5705.patch
#rm -rf ./feeds/luci/applications/luci-app-upnp
#cp -rf ../immortalwrt_luci_21/applications/luci-app-upnp ./feeds/luci/applications/luci-app-upnp
sed -i '/firewall/d' ./.config
sed -i '/offload/d' ./.config
sed -i '/tables/d' ./.config
sed -i '/nft/d' ./.config
sed -i '/Nft/d' ./.config
sed -i '/homeproxy/d' ./.config
sed -i '/nikki/d' ./.config
echo '
CONFIG_PACKAGE_firewall=y
# CONFIG_PACKAGE_firewall4 is not set
# CONFIG_PACKAGE_iptables-nft is not set
CONFIG_PACKAGE_iptables-zz-legacy=y
# CONFIG_PACKAGE_ip6tables-nft is not set
CONFIG_PACKAGE_ip6tables-zz-legacy=y
CONFIG_PACKAGE_xtables-legacy=y
# CONFIG_PACKAGE_xtables-nft is not set
CONFIG_PACKAGE_kmod-nft-offload=n
CONFIG_PACKAGE_kmod-ipt-offload=y
CONFIG_PACKAGE_dnsmasq_full_ipset=y
CONFIG_PACKAGE_dnsmasq_full_nftset=n
CONFIG_PACKAGE_iptables-mod-fullconenat=y
CONFIG_PACKAGE_luci-app-passwall=y
#将miniupnpd
CONFIG_PACKAGE_miniupnpd-iptables=y
CONFIG_PACKAGE_miniupnpd-nftables=n
' >>./.config
rm -rf ./feeds/luci/applications/luci-app-zerotier
cp -rf ../lede_luci/applications/luci-app-zerotier ./feeds/luci/applications/luci-app-zerotier
#wget -P feeds/luci/applications/luci-app-zerotier/ https://github.com/QiuSimons/OpenWrt-Add/raw/master/move_2_services.sh
#chmod -R 755 ./feeds/luci/applications/luci-app-zerotier/move_2_services.sh
#pushd feeds/luci/applications/luci-app-zerotier
#bash move_2_services.sh
#popd
ln -sf ../../../feeds/luci/applications/luci-app-zerotier ./package/feeds/luci/luci-app-zerotier

#exit 0

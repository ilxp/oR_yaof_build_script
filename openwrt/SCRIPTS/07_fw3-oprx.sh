#!/bin/bash
# 滚回fw3
# FW3 24.10不在支持bcm-fullconenat
mkdir -p package/network/config/firewall/patches
cp -rf ../immortalwrt_24/package/network/config/firewall/patches/fullconenat.patch ./package/network/config/firewall/patches/fullconenat.patch
#cp -rf ../immortalwrt_21/package/network/config/firewall/patches/100-fullconenat.patch ./package/network/config/firewall/patches/100-fullconenat.patch
#cp -rf ../immortalwrt_21/package/network/config/firewall/patches/101-bcm-fullconenat.patch ./package/network/config/firewall/patches/101-bcm-fullconenat.patch
# iptables
#cp -rf ../immortalwrt_21/package/network/utils/iptables/patches/900-bcm-fullconenat.patch ./package/network/utils/iptables/patches/900-bcm-fullconenat.patch
cp -rf ../immortalwrt_24/package/network/utils/iptables/patches/800-flowoffload_target.patch ./package/network/utils/iptables/patches/800-flowoffload_target.patch

# network
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1

# luci滚回fw3：Patch LuCI 以增添 FullCone 开关  #luci-app-firewall_add_fullcone_fw3.patch
pushd feeds/luci
#patch -Rp1 <../../../PATCH/pkgs/firewall/luci/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
patch -p1 <../../../data/patches/firewall3/luci-app-firewall_add_fullcone_fw3.patch
#wget -qO- https://github.com/openwrt/luci/commit/471182b2.patch | patch -p1  #和上面的一样
popd

#上面已经回滚
#patch -Rp1 < ../PATCH/pkgs/firewall/luci/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
#patch -p1 < ../data/patches/firewall3/luci-app-firewall_add_fullcone_fw3.patch

# FullCone PKG  #来源lede immortalwrtde 要新，支持ipv6
#cp -rf ../lede/package/network/services/fullconenat  ./package/network/utils/fullconenat
cp -rf ../immortalwrt_24/package/network/utils/fullconenat  ./package/network/utils/fullconenat

#sed -i 's,iptables-nft,iptables-legacy,g' ./package/new/luci-app-passwall2/Makefile
#sed -i 's,iptables-nft,iptables-legacy,g' ./package/helloworld/luci-app-passwall/Makefile
sed -i 's,iptables-nft +kmod-nft-fullcone,iptables-mod-fullconenat,g' ./package/new/addition-trans-zh/Makefile
#sed -i 's,+iptables-nft +kmod-nft-fullcone,,g' ./package/new/addition-trans-zh/Makefile

#rm -rf ./feeds/packages/net/miniupnpd
#cp -rf ../immortalwrt_pkg_21/net/miniupnpd ./feeds/packages/net/miniupnpd
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
#cp -rf ../immortalwrt_luci_24/applications/luci-app-upnp ./feeds/luci/applications/luci-app-upnp

# UPnP
rm -rf feeds/{packages/net/miniupnpd,luci/applications/luci-app-upnp}
git clone https://git.cooluc.com/sbwml/miniupnpd feeds/packages/net/miniupnpd -b v2.3.6
git clone https://git.cooluc.com/sbwml/luci-app-upnp feeds/luci/applications/luci-app-upnp -b openwrt-24.10
#cp -rf ../lede_luci/applications/luci-app-upnp ./feeds/luci/applications/luci-app-upnp

# 精简 UPnP 菜单名称和移动
sed -i 's#\"title\": \"UPnP IGD \& PCP/NAT-PMP\"#\"title\": \"UPnP\"#g' feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json
sed -i 's,UPnP IGD 和 PCP,UPnP,g' feeds/luci/applications/luci-app-upnp/po/zh_Hans/upnp.po
sed -i "s/network/services/g" feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json

#删除nftables
rm -rf package/network/utils/nftables
rm -rf package/kernel/nat6
#nat46
cp -rf ../immortalwrt_24/package/kernel/nat46 ./package/kernel/nat46

#修改dnsmasq，去掉nftables-json
sed -i 's,+PACKAGE_dnsmasq_full_nftset:nftables-json,,g' ./package/network/services/dnsmasq/Makefile

# sbwml大神 【采用官方自由的iptables】
rm -rf feeds/luci/applications/luci-app-dockerman
cp -rf ../lede_luci/applications/luci-app-dockerman ./feeds/luci/applications/luci-app-dockerman
rm -rf feeds/packages/utils/dockerd
#rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}
#cp -rf ../immortalwrt_pkg_24/utils/docker ./feeds/packages/utils/docker
cp -rf ../immortalwrt_pkg_24/utils/dockerd ./feeds/packages/utils/dockerd
#cp -rf ../immortalwrt_pkg_24/utils/containerd ./feeds/packages/utils/containerd
#cp -rf ../immortalwrt_pkg_24/utils/runc ./feeds/packages/utils/runc

#rm -rf feeds/luci/applications/luci-app-turboacc  #安装不上
#rm -rf package/new/turboacc
#cp -rf ../lede_luci/applications/luci-app-turboacc ./feeds/luci/applications/luci-app-turboacc
#修改 bbr为bbr3
#sed -i 's/kmod-tcp-bbr/kmod-tcp-bbr3/g' feeds/luci/applications/luci-app-turboacc/Makefile

rm -rf package/diy/gargoyle-qos-openwrt
git clone -b ipt https://github.com/ilxp/gargoyle-qos-openwrt.git  package/diy/gargoyle-qos-openwrt
#增加ndpi依iptables-mod
#sed -i 's,+qos-gargoyle,+qos-gargoyle +iptables-mod-ndpi,g' package/diy/gargoyle-qos-openwrt/luci-app-qos-gargoyle/Makefile

sed -i '/firewall/d' ./.config
sed -i '/offload/d' ./.config
sed -i '/tables/d' ./.config
sed -i '/nft/d' ./.config
sed -i '/nftables/d' ./.config
sed -i '/Nft/d' ./.config
sed -i '/homeproxy/d' ./.config
sed -i '/mihomo/d' ./.config
sed -i '/qosmate/d' ./.config
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
CONFIG_PACKAGE_luci-app-qos-gargoyle=y
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_sqm-scripts=y
CONFIG_PACKAGE_sqm-scripts-extra=y
CONFIG_PACKAGE_fullconenat=y
CONFIG_PACKAGE_miniupnpd-nftables=n
CONFIG_PACKAGE_nftables-json=n
CONFIG_PACKAGE_nat6=n
CONFIG_PACKAGE_nat46=y
CONFIG_PACKAGE_miniupnpd-iptables=y
CONFIG_PACKAGE_luci-app-passwall=n
CONFIG_PACKAGE_luci-app-ssr-plus=n
CONFIG_PACKAGE_luci-app-turboacc=n  #安装不上
' >>./.config
rm -rf ./feeds/luci/applications/luci-app-zerotier
cp -rf ../lede_luci/applications/luci-app-zerotier ./feeds/luci/applications/luci-app-zerotier
wget -P feeds/luci/applications/luci-app-zerotier/ https://github.com/QiuSimons/OpenWrt-Add/raw/master/move_2_services.sh
chmod -R 755 ./feeds/luci/applications/luci-app-zerotier/move_2_services.sh
pushd feeds/luci/applications/luci-app-zerotier
bash move_2_services.sh
popd
ln -sf ../../../feeds/luci/applications/luci-app-zerotier ./package/feeds/luci/luci-app-zerotier

#exit 0

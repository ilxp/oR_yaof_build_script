#!/bin/bash
clear

##复制过来

#################自定义克隆功能函数以及导入PATCH目录===============
#在02_prepare_package.sh中第二行clear增加如下代码：
#git clone -b main --single-branch https://github.com/ilxp/oR_yaof_build_script.git ./diydata  #结果是./diydata/openwrt/PATCH
#cd  ./diydata
#git sparse-checkout init --cone 
#git sparse-checkout set openwrt/PATCH
#rm -rf .git
#rm -rf .github
#rm -rf .gitignore
#rm -rf *.md
#rm -rf *.txt
#rm -rf *.sh
#rm -rf .gitattributes
#rm -rf LICENSE
#cd ..
#并将../PATCH替换为./diydata/openwrt/data/PATCH 即可。其余不改变

#第二种  来源https://github.com/Jejz168/OpenWrt
mkdir package/new
function merge_package() {
	# 参数1是分支名,参数2是库地址,参数3是所有文件下载到指定路径。
	# 同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开。
	# 示例:
	# merge_package 分支 仓库地址 下载到指定路径(已存在或者自定义) 目标文件（多个空格分开）
	# 下载到不存在的目录时: rm -rf package/new; mkdir package/new
	# merge_package master https://github.com/WYC-2020/openwrt-packages package/openwrt-packages luci-app-eqos luci-app-openclash luci-app-ddnsto ddnsto 
	# merge_package master https://github.com/lisaac/luci-app-dockerman package/lean applications/luci-app-dockerman #结果是将luci-app-dockerman放在package/lean下
	# merge_package main https://github.com/linkease/nas-packages-luci package/new luci/luci-app-ddnsto  #结果是package/new/luci-app-ddnsto
	# merge_package master https://github.com/linkease/nas-packages package/new network/services/ddnsto  #结果是package/new/ddnsto 
	# merge_package master https://github.com/coolsnowwolf/lede package/kernel package/kernel/mac80211  #将目标仓库的package/kernel/mac80211克隆到本地package/kernel下
	if [[ $# -lt 3 ]]; then
		echo "Syntax error: [$#] [$*]" >&2
		return 1
	fi
	trap 'rm -rf "$tmpdir"' EXIT
	branch="$1" curl="$2" target_dir="$3" && shift 3
	rootdir="$PWD"
	localdir="$target_dir"
	[ -d "$localdir" ] || mkdir -p "$localdir"
	tmpdir="$(mktemp -d)" || exit 1
        echo "开始下载：$(echo $curl | awk -F '/' '{print $(NF)}')"
	git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$curl" "$tmpdir"
	cd "$tmpdir"
	git sparse-checkout init --cone
	git sparse-checkout set "$@"
	# 使用循环逐个移动文件夹
	for folder in "$@"; do
		mv -f "$folder" "$rootdir/$localdir"
	done
	cd "$rootdir"
}
##使用函数导入
merge_package main https://github.com/ilxp/oR_yaof_build_script.git ./diydata openwrt/PATCH  #结果是./diydata/PATCH
#并将../PATCH替换为./diydata/PATCH 即可。其余不改变。

merge_package main https://github.com/ilxp/oR_yaof_build_script.git ./diydata openwrt/data  #结果是./diydata/data

#去除280行# Lets Fuck部分  
#去除198行 ### ADD PKG 部分 ### 的第一行。下面删除的，再获取

#================================结束==============================================================
### 基础部分 ###
# 使用 O2 级别的优化
sed -i 's/Os/O2/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
# 移除 SNAPSHOT 标签
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
sed -i '/CONFIG_BUILDBOT/d' include/feeds.mk
sed -i 's/;)\s*\\/; \\/' include/feeds.mk
# Nginx
sed -i "s/large_client_header_buffers 2 1k/large_client_header_buffers 4 32k/g" feeds/packages/net/nginx-util/files/uci.conf.template
sed -i "s/client_max_body_size 128M/client_max_body_size 2048M/g" feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/client_max_body_size/a\\tclient_body_buffer_size 8192M;' feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/client_max_body_size/a\\tserver_names_hash_bucket_size 128;' feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/ubus_parallel_req/a\        ubus_script_timeout 600;' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -ri "/luci-webui.socket/i\ \t\tuwsgi_send_timeout 600\;\n\t\tuwsgi_connect_timeout 600\;\n\t\tuwsgi_read_timeout 600\;" feeds/packages/net/nginx/files-luci-support/luci.locations
sed -ri "/luci-cgi_io.socket/i\ \t\tuwsgi_send_timeout 600\;\n\t\tuwsgi_connect_timeout 600\;\n\t\tuwsgi_read_timeout 600\;" feeds/packages/net/nginx/files-luci-support/luci.locations
# uwsgi
sed -i 's,procd_set_param stderr 1,procd_set_param stderr 0,g' feeds/packages/net/uwsgi/files/uwsgi.init
sed -i 's,buffer-size = 10000,buffer-size = 131072,g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's,logger = luci,#logger = luci,g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i '$a cgi-timeout = 600' feeds/packages/net/uwsgi/files-luci-support/luci-*.ini
sed -i 's/threads = 1/threads = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/processes = 3/processes = 4/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/cheaper = 1/cheaper = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
# rpcd
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js

### FW4 ###
rm -rf ./package/network/config/firewall4
#cp -rf ../openwrt_ma/package/network/config/firewall4 ./package/network/config/firewall4
merge_package main https://github.com/openwrt/openwrt.git package/network/config package/network/config/firewall4

### 必要的 Patches ###
# TCP optimizations
cp -rf ./diydata/PATCH/kernel/6.7_Boost_For_Single_TCP_Flow/* ./target/linux/generic/backport-6.6/
cp -rf ./diydata/PATCH/kernel/6.8_Boost_TCP_Performance_For_Many_Concurrent_Connections-bp_but_put_in_hack/* ./target/linux/generic/hack-6.6/
cp -rf ./diydata/PATCH/kernel/6.8_Better_data_locality_in_networking_fast_paths-bp_but_put_in_hack/* ./target/linux/generic/hack-6.6/
# UDP optimizations
cp -rf ./diydata/PATCH/kernel/6.7_FQ_packet_scheduling/* ./target/linux/generic/backport-6.6/
# Patch arm64 型号名称
cp -rf ./diydata/PATCH/kernel/arm/* ./target/linux/generic/hack-6.6/
# BBRv3
cp -rf ./diydata/PATCH/kernel/bbr3/* ./target/linux/generic/backport-6.6/
# LRNG
cp -rf ./diydata/PATCH/kernel/lrng/* ./target/linux/generic/hack-6.6/
echo '
# CONFIG_RANDOM_DEFAULT_IMPL is not set
CONFIG_LRNG=y
CONFIG_LRNG_DEV_IF=y
# CONFIG_LRNG_IRQ is not set
CONFIG_LRNG_JENT=y
CONFIG_LRNG_CPU=y
# CONFIG_LRNG_SCHED is not set
CONFIG_LRNG_SELFTEST=y
# CONFIG_LRNG_SELFTEST_PANIC is not set
' >>./target/linux/generic/config-6.6
# wg
cp -rf ./diydata/PATCH/kernel/wg/* ./target/linux/generic/hack-6.6/
# dont wrongly interpret first-time data
echo "net.netfilter.nf_conntrack_tcp_max_retrans=5" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# OTHERS
cp -rf ./diydata/PATCH/kernel/others/* ./target/linux/generic/pending-6.6/
# 6.17_ppp_performance
wget https://github.com/torvalds/linux/commit/95d0d094.patch -O target/linux/generic/pending-6.6/999-1-95d0d09.patch
wget https://github.com/torvalds/linux/commit/1a3e9b7a.patch -O target/linux/generic/pending-6.6/999-2-1a3e9b7.patch
wget https://github.com/torvalds/linux/commit/7eebd219.patch -O target/linux/generic/pending-6.6/999-3-7eebd21.patch
# ppp_fix
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/9d852a0.patch | patch -p1

#### fullconenat-nft
#fullconenat-nft
rm -rf package/new/nft-fullcone
merge_package master https://github.com/immortalwrt/immortalwrt.git package/network/utils package/network/utils/fullconenat-nft
merge_package master https://github.com/immortalwrt/immortalwrt.git package/network/utils package/network/utils/fullconenat


### Fullcone-NAT 部分 ###
# bcmfullcone
cp -rf ./diydata/PATCH/kernel/bcmfullcone/* ./target/linux/generic/hack-6.6/
# set nf_conntrack_expect_max for fullcone
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# FW4
mkdir -p package/network/config/firewall4/patches
#cp -f ./diydata/PATCH/pkgs/firewall/firewall4_patches/*.patch ./package/network/config/firewall4/patches/
mkdir -p package/libs/libnftnl/patches
cp -f ./diydata/PATCH/pkgs/firewall/libnftnl/*.patch ./package/libs/libnftnl/patches/
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
mkdir -p package/network/utils/nftables/patches

#cp -f ./diydata/PATCH/pkgs/firewall/nftables/*.patch ./package/network/utils/nftables/patches/  #编译不成功 
#采用sbwml的
cp -f ./diydata/data/patches/nftables/*.patch ./package/network/utils/nftables/patches/

# Patch LuCI 以增添 FullCone 开关
pushd feeds/luci
patch -p1 <../.././diydata/PATCH/pkgs/firewall/luci/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
popd

### Shortcut-FE 部分 ###
# Patch Kernel 以支持 Shortcut-FE
cp -rf ./diydata/PATCH/kernel/sfe/* ./target/linux/generic/hack-6.6/
#cp -rf ../lede/target/linux/generic/pending-6.6/613-netfilter_optional_tcp_window_check.patch ./target/linux/generic/pending-6.6/613-netfilter_optional_tcp_window_check.patch
wget -P target/linux/generic/pending-6.6/ https://github.com/coolsnowwolf/lede/raw/master/target/linux/generic/pending-6.6/613-netfilter_optional_tcp_window_check.patch

# Patch LuCI 以增添 Shortcut-FE 开关
pushd feeds/luci
patch -p1 <../.././diydata/PATCH/pkgs/firewall/luci/0002-luci-app-firewall-add-shortcut-fe-option.patch
popd

### NAT6 部分 ###
# custom nft command
patch -p1 < ./diydata/PATCH/pkgs/firewall/100-openwrt-firewall4-add-custom-nft-command-support.patch
cp -f ./diydata/PATCH/pkgs/firewall/firewall4_patches/*.patch ./package/network/config/firewall4/patches/
# Patch LuCI 以增添 NAT6 开关
pushd feeds/luci
patch -p1 <../.././diydata/PATCH/pkgs/firewall/luci/0003-luci-app-firewall-add-ipv6-nat-option.patch
popd
# Patch LuCI 以支持自定义 nft 规则
pushd feeds/luci
patch -p1 <../.././diydata/PATCH/pkgs/firewall/luci/0004-luci-add-firewall-add-custom-nft-rule-support.patch
popd

### natflow 部分 ###
pushd feeds/luci
patch -p1 <../.././diydata/PATCH/pkgs/firewall/luci/0005-luci-app-firewall-add-natflow-offload-support.patch
popd

### fullcone6 ###
pushd feeds/luci
patch -p1 <../.././diydata//PATCH/pkgs/firewall/luci/0007-luci-app-firewall-add-fullcone6-option-for-nftables-.patch
popd

### Other Kernel Hack 部分 ###
# make olddefconfig
wget -qO - https://github.com/openwrt/openwrt/commit/c21a3570.patch | patch -p1
# igc-fix
#cp -rf ../lede/target/linux/x86/patches-6.6/996-intel-igc-i225-i226-disable-eee.patch ./target/linux/x86/patches-6.6/996-intel-igc-i225-i226-disable-eee.patch
wget -P target/linux/x86/patches-6.6/ https://github.com/coolsnowwolf/lede/raw/master/target/linux/x86/patches-6.6/996-intel-igc-i225-i226-disable-eee.patch

# btf
cp -rf ./diydata/PATCH/kernel/btf/* ./target/linux/generic/hack-6.6/

### 获取额外的基础软件包 ###
# 更换为 ImmortalWrt Uboot 以及 Target
rm -rf ./target/linux/rockchip
#cp -rf ../immortalwrt_24/target/linux/rockchip ./target/linux/rockchip
merge_package openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git target/linux target/linux/rockchip
cp -rf ./diydata/PATCH/kernel/rockchip/* ./target/linux/rockchip/patches-6.6/
#wget https://github.com/immortalwrt/immortalwrt/raw/refs/tags/v23.05.4/target/linux/rockchip/patches-5.15/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch -O target/linux/rockchip/patches-6.6/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch
rm -rf package/boot/{rkbin,uboot-rockchip,arm-trusted-firmware-rockchip}
#cp -rf ../immortalwrt_24/package/boot/uboot-rockchip ./package/boot/uboot-rockchip
#cp -rf ../immortalwrt_24/package/boot/arm-trusted-firmware-rockchip ./package/boot/arm-trusted-firmware-rockchip

merge_package openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git package/boot package/boot/uboot-rockchip
merge_package openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git package/boot package/boot/arm-trusted-firmware-rockchip
sed -i '/REQUIRE_IMAGE_METADATA/d' target/linux/rockchip/armv8/base-files/lib/upgrade/platform.sh
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/default.bootscript
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg


### ADD PKG 部分 ###
#cp -rf ../OpenWrt-Add ./package/new
rm -rf feeds/packages/net/{xray-core,v2ray-core,v2ray-geodata,sing-box,frp,microsocks,shadowsocks-libev,zerotier,daed}
rm -rf feeds/luci/applications/{luci-app-frps,luci-app-frpc,luci-app-zerotier,luci-app-filemanager}
rm -rf feeds/packages/utils/coremark

merge_package master https://github.com/QiuSimons/OpenWrt-Add.git package/new openwrt_helloworld/xray-core openwrt_helloworld/v2ray-core openwrt_helloworld/v2ray-geodata openwrt_helloworld/sing-box luci-app-frps luci-app-frpc imm_pkg/frp openwrt_helloworld/microsocks openwrt_helloworld/shadowsocks-libev openwrt_pkgs/coremark

### 获取额外的 LuCI 应用、主题和依赖 ###
# 更换 Nodejs 版本
rm -rf ./feeds/packages/lang/node
rm -rf ./package/new/feeds_packages_lang_node-prebuilt
#cp -rf ../OpenWrt-Add/feeds_packages_lang_node-prebuilt ./feeds/packages/lang/node
#merge_package master https://github.com/QiuSimons/OpenWrt-Add.git package/new feeds_packages_lang_node-prebuilt
git clone https://github.com/sbwml/feeds_packages_lang_node-prebuilt -b packages-24.10 feeds/packages/lang/node

# 更换 golang 版本
rm -rf ./feeds/packages/lang/golang
#cp -rf ../openwrt_pkg_ma/lang/golang ./feeds/packages/lang/golang
cp -rf ../lede_pkg_ma/lang/golang ./feeds/packages/lang/golang
# rust
wget https://github.com/rust-lang/rust/commit/e8d97f0.patch -O feeds/packages/lang/rust/patches/e8d97f0.patch
# mount cgroupv2
pushd feeds/packages
patch -p1 <../.././diydata/PATCH/pkgs/cgroupfs-mount/0001-fix-cgroupfs-mount.patch
popd
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cp -rf ./diydata/PATCH/pkgs/cgroupfs-mount/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ./diydata/PATCH/pkgs/cgroupfs-mount/901-fix-cgroupfs-umount.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ./diydata/PATCH/pkgs/cgroupfs-mount/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch ./feeds/packages/utils/cgroupfs-mount/patches/
# fstool
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
# Boost 通用即插即用
rm -rf ./feeds/packages/net/miniupnpd
#cp -rf ../openwrt_pkg_ma/net/miniupnpd ./feeds/packages/net/miniupnpd
merge_package master https://github.com/openwrt/packages.git feeds/packages/net net/miniupnpd
wget https://github.com/miniupnp/miniupnp/commit/0e8c68d.patch -O feeds/packages/net/miniupnpd/patches/0e8c68d.patch
sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/0e8c68d.patch
wget https://github.com/miniupnp/miniupnp/commit/21541fc.patch -O feeds/packages/net/miniupnpd/patches/21541fc.patch
sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/21541fc.patch
wget https://github.com/miniupnp/miniupnp/commit/b78a363.patch -O feeds/packages/net/miniupnpd/patches/b78a363.patch
sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/b78a363.patch
wget https://github.com/miniupnp/miniupnp/commit/8f2f392.patch -O feeds/packages/net/miniupnpd/patches/8f2f392.patch
sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/8f2f392.patch
wget https://github.com/miniupnp/miniupnp/commit/60f5705.patch -O feeds/packages/net/miniupnpd/patches/60f5705.patch
sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/60f5705.patch
wget https://github.com/miniupnp/miniupnp/commit/3f3582b.patch -O feeds/packages/net/miniupnpd/patches/3f3582b.patch
sed -i 's,/miniupnpd/,/,g' ./feeds/packages/net/miniupnpd/patches/3f3582b.patch
cp -rf ./diydata/PATCH/pkgs/miniupnpd/301-options-force_forwarding-support.patch ./feeds/packages/net/miniupnpd/patches/
pushd feeds/packages
patch -p1 <../.././diydata/PATCH/pkgs/miniupnpd/01-set-presentation_url.patch
patch -p1 <../.././diydata/PATCH/pkgs/miniupnpd/02-force_forwarding.patch
popd
pushd feeds/luci
patch -p1 <../.././diydata/PATCH/pkgs/miniupnpd/luci-upnp-support-force_forwarding-flag.patch
popd
# 动态DNS
sed -i '/boot()/,+2d' feeds/packages/net/ddns-scripts/files/etc/init.d/ddns
# Docker 容器
rm -rf ./feeds/luci/applications/luci-app-dockerman
#cp -rf ../dockerman/applications/luci-app-dockerman ./feeds/luci/applications/luci-app-dockerman
merge_package master https://github.com/lisaac/luci-app-dockerman.git feeds/luci/applications applications/luci-app-dockerman

sed -i '/auto_start/d' feeds/luci/applications/luci-app-dockerman/root/etc/uci-defaults/luci-app-dockerman
pushd feeds/packages
wget -qO- https://github.com/openwrt/packages/commit/e2e5ee69.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/pull/20054.patch | patch -p1
popd
sed -i '/sysctl.d/d' feeds/packages/utils/dockerd/Makefile
rm -rf ./feeds/luci/collections/luci-lib-docker
#cp -rf ../docker_lib/collections/luci-lib-docker ./feeds/luci/collections/luci-lib-docker
merge_package master https://github.com/lisaac/luci-lib-docker.git package/new collections/luci-lib-docker

# IPv6 兼容助手
patch -p1 <./diydata/PATCH/pkgs/odhcp6c/1002-odhcp6c-support-dhcpv6-hotplug.patch
# ODHCPD
rm -rf ./package/network/services/odhcpd
cp -rf ../openwrt_ma/package/network/services/odhcpd ./package/network/services/odhcpd
mkdir -p package/network/ipv6/odhcp6c/patches
wget https://github.com/openwrt/odhcp6c/pull/75.patch -O package/network/ipv6/odhcp6c/patches/75.patch
wget https://github.com/openwrt/odhcp6c/pull/80.patch -O package/network/ipv6/odhcp6c/patches/80.patch
wget https://github.com/openwrt/odhcp6c/pull/82.patch -O package/network/ipv6/odhcp6c/patches/82.patch
wget https://github.com/openwrt/odhcp6c/pull/83.patch -O package/network/ipv6/odhcp6c/patches/83.patch
wget https://github.com/openwrt/odhcp6c/pull/84.patch -O package/network/ipv6/odhcp6c/patches/84.patch
wget https://github.com/openwrt/odhcp6c/pull/90.patch -O package/network/ipv6/odhcp6c/patches/90.patch
wget https://github.com/openwrt/odhcp6c/pull/98.patch -O package/network/ipv6/odhcp6c/patches/98.patch
# watchcat
echo > ./feeds/packages/utils/watchcat/files/watchcat.config
# 默认开启 Irqbalance
#sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config

# 使用 TEO CPU 空闲调度器
KERNEL_VERSION="6.6"
CONFIG_CONTENT='
CONFIG_CPU_IDLE_GOV_MENU=n
CONFIG_CPU_IDLE_GOV_TEO=y
'
# 查找所有与内核 6.6 相关的配置文件并将这些配置项追加到文件末尾
find ./target/linux/ -name "config-${KERNEL_VERSION}" | xargs -I{} sh -c "echo '$CONFIG_CONTENT' | tee -a {} > /dev/null"


### 最后的收尾工作 ###
# Lets Fuck
#mkdir -p package/base-files/files/usr/bin
#cp -rf ../OpenWrt-Add/fuck ./package/base-files/files/usr/bin/fuck
# 生成默认配置及缓存
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-6.6

#exit 0

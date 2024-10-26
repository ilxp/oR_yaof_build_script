#!/bin/bash
clear

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
rm -rf package/new
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

#去除280行# Lets Fuck部分  
#去除198行 ### ADD PKG 部分 ### 的第一行。下面删除的，再获取

#获取部分ADD的删除的pkg
merge_package master https://github.com/QiuSimons/OpenWrt-Add.git package/new openwrt_helloworld/xray-core openwrt_helloworld/v2ray-core openwrt_helloworld/v2ray-geodata openwrt_helloworld/sing-box luci-app-frps luci-app-frpc imm_pkg/frp openwrt_helloworld/microsocks openwrt_helloworld/shadowsocks-libev openwrt_pkgs/coremark

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
cp -rf ../openwrt_ma/package/network/config/firewall4 ./package/network/config/firewall4

### 必要的 Patches ###
# TCP optimizations
cp -rf ./diydata/PATCH/backport/TCP/* ./target/linux/generic/backport-5.15/
# x86_csum
cp -rf ./diydata/PATCH/backport/x86_csum/* ./target/linux/generic/backport-5.15/
# Patch arm64 型号名称
cp -rf ../immortalwrt_23/target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch ./target/linux/generic/hack-5.15/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# BBRv3
cp -rf ./diydata/PATCH/BBRv3/kernel/* ./target/linux/generic/backport-5.15/
# LRNG
cp -rf ./diydata/PATCH/LRNG/* ./target/linux/generic/hack-5.15/
echo '
# CONFIG_RANDOM_DEFAULT_IMPL is not set
CONFIG_LRNG=y
# CONFIG_LRNG_IRQ is not set
CONFIG_LRNG_JENT=y
CONFIG_LRNG_CPU=y
# CONFIG_LRNG_SCHED is not set
' >>./target/linux/generic/config-5.15
# wg
cp -rf ./diydata/PATCH/wg/* ./target/linux/generic/hack-5.15/
# dont wrongly interpret first-time data
echo "net.netfilter.nf_conntrack_tcp_max_retrans=5" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf

### Fullcone-NAT 部分 ###
# Patch Kernel 以解决 FullCone 冲突
cp -rf ../lede/target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch ./target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch
# bcmfullcone
cp -a ./diydata/PATCH/bcmfullcone/*.patch target/linux/generic/hack-5.15/
# set nf_conntrack_expect_max for fullcone
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# FW4
mkdir -p package/network/config/firewall4/patches
cp -f ./diydata/PATCH/firewall/firewall4_patches/*.patch ./package/network/config/firewall4/patches/
mkdir -p package/libs/libnftnl/patches
cp -f ./diydata/PATCH/firewall/libnftnl/*.patch ./package/libs/libnftnl/patches/
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
mkdir -p package/network/utils/nftables/patches
cp -f ./diydata/PATCH/firewall/nftables/*.patch ./package/network/utils/nftables/patches/
# Patch LuCI 以增添 FullCone 开关
pushd feeds/luci
patch -p1 <../.././diydata/PATCH/firewall/01-luci-app-firewall_add_nft-fullcone-bcm-fullcone_option.patch
popd

### Shortcut-FE 部分 ###
# Patch Kernel 以支持 Shortcut-FE
cp -rf ../lede/target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch ./target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
cp -f ./diydata/PATCH/backport/sfe/601-netfilter-export-udp_get_timeouts-function.patch ./target/linux/generic/hack-5.15/
cp -rf ../lede/target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch ./target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch
# Patch LuCI 以增添 Shortcut-FE 开关
patch -p1 < ./diydata/PATCH/firewall/luci-app-firewall_add_sfe_switch.patch
# natflow
# patch -p1 < ./diydata/PATCH/firewall/luci-app-firewall_add_natflow_switch.patch

### NAT6 部分 ###
pushd feeds/luci
# custom nft command
patch -p1 <../.././diydata/PATCH/firewall/100-openwrt-firewall4-add-custom-nft-command-support.patch
# Patch LuCI 以增添 NAT6 开关
patch -p1 <../.././diydata/PATCH/firewall/03-luci-app-firewall_add_ipv6-nat.patch
# Patch LuCI 以支持自定义 nft 规则
patch -p1 <../.././diydata/PATCH/firewall/04-luci-add-firewall4-nft-rules-file.patch
popd

### Other Kernel Hack 部分 ###
# make olddefconfig
wget -qO - https://github.com/openwrt/openwrt/commit/c21a3570.patch | patch -p1
# igc-fix
cp -rf ../lede/target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch ./target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch
# btf
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/73e5679.patch | patch -p1
wget https://github.com/immortalwrt/immortalwrt/raw/openwrt-23.05/target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch -O target/linux/generic/backport-5.15/051-v5.18-bpf-Add-config-to-allow-loading-modules-with-BTF-mismatch.patch
# bpf_loop
cp -f ./diydata/PATCH/bpf_loop/*.patch ./target/linux/generic/backport-5.15/

### 获取额外的基础软件包 ###
# 更换为 ImmortalWrt Uboot 以及 Target
rm -rf ./target/linux/rockchip
cp -rf ../immortalwrt_23/target/linux/rockchip ./target/linux/rockchip
cp -rf ./diydata/PATCH/rockchip-5.15/* ./target/linux/rockchip/patches-5.15/
rm -rf ./package/boot/uboot-rockchip
cp -rf ../immortalwrt_23/package/boot/uboot-rockchip ./package/boot/uboot-rockchip
rm -rf ./package/boot/arm-trusted-firmware-rockchip
cp -rf ../immortalwrt_23/package/boot/arm-trusted-firmware-rockchip ./package/boot/arm-trusted-firmware-rockchip
sed -i '/REQUIRE_IMAGE_METADATA/d' target/linux/rockchip/armv8/base-files/lib/upgrade/platform.sh
# intel-firmware
wget -qO - https://github.com/openwrt/openwrt/commit/9c58add.patch | patch -p1
wget -qO - https://github.com/openwrt/openwrt/commit/64f1a65.patch | patch -p1
sed -i '/I915/d' target/linux/x86/64/config-5.15
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/default.bootscript
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-efi.cfg
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-iso.cfg
sed -i 's,@CMDLINE@ noinitrd,noinitrd mitigations=off,g' target/linux/x86/image/grub-pc.cfg

### ADD PKG 部分 ###
#cp -rf ../OpenWrt-Add ./package/new
rm -rf feeds/packages/net/{xray-core,v2ray-core,v2ray-geodata,sing-box}
rm -rf feeds/luci/applications/{luci-app-frps,luci-app-frpc}
rm -rf feeds/packages/net/{frp,microsocks,shadowsocks-libev}
rm -rf feeds/packages/utils/coremark

### 获取额外的 LuCI 应用、主题和依赖 ###
# 更换 Nodejs 版本
rm -rf ./feeds/packages/lang/node
rm -rf ./package/new/feeds_packages_lang_node-prebuilt
cp -rf ../OpenWrt-Add/feeds_packages_lang_node-prebuilt ./feeds/packages/lang/node
# 更换 golang 版本
rm -rf ./feeds/packages/lang/golang
cp -rf ../openwrt_pkg_ma/lang/golang ./feeds/packages/lang/golang
# mount cgroupv2
pushd feeds/packages
patch -p1 <../.././diydata/PATCH/cgroupfs-mount/0001-fix-cgroupfs-mount.patch
popd
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cp -rf ./diydata/PATCH/cgroupfs-mount/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ./diydata/PATCH/cgroupfs-mount/901-fix-cgroupfs-umount.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ./diydata/PATCH/cgroupfs-mount/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch ./feeds/packages/utils/cgroupfs-mount/patches/
# fstool
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
# dae
rm -rf ./feeds/packages/net/daed
rm -rf ./package/new/luci-app-daed
git clone -b test --depth 1 https://github.com/QiuSimons/luci-app-daed package/new/luci-app-daed
# Boost 通用即插即用
rm -rf ./feeds/packages/net/miniupnpd
cp -rf ../openwrt_pkg_ma/net/miniupnpd ./feeds/packages/net/miniupnpd
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
cp -rf ./diydata/PATCH/miniupnpd/301-options-force_forwarding-support.patch ./feeds/packages/net/miniupnpd/patches/
pushd feeds/packages
patch -p1 <../.././diydata/PATCH/miniupnpd/01-set-presentation_url.patch
patch -p1 <../.././diydata/PATCH/miniupnpd/02-force_forwarding.patch
popd
pushd feeds/luci
wget -qO- https://github.com/openwrt/luci/commit/0b5fb915.patch | patch -p1
popd
# 动态DNS
sed -i '/boot()/,+2d' feeds/packages/net/ddns-scripts/files/etc/init.d/ddns
# Docker 容器
rm -rf ./feeds/luci/applications/luci-app-dockerman
cp -rf ../dockerman/applications/luci-app-dockerman ./feeds/luci/applications/luci-app-dockerman
sed -i '/auto_start/d' feeds/luci/applications/luci-app-dockerman/root/etc/uci-defaults/luci-app-dockerman
pushd feeds/packages
wget -qO- https://github.com/openwrt/packages/commit/e2e5ee69.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/pull/20054.patch | patch -p1
popd
sed -i '/sysctl.d/d' feeds/packages/utils/dockerd/Makefile
rm -rf ./feeds/luci/collections/luci-lib-docker
cp -rf ../docker_lib/collections/luci-lib-docker ./feeds/luci/collections/luci-lib-docker
# IPv6 兼容助手
patch -p1 <./diydata/PATCH/odhcp6c/1002-odhcp6c-support-dhcpv6-hotplug.patch
# ODHCPD
mkdir -p package/network/services/odhcpd/patches
cp -f ./diydata/PATCH/odhcpd/0001-odhcpd-improve-RFC-9096-compliance.patch ./package/network/services/odhcpd/patches/0001-odhcpd-improve-RFC-9096-compliance.patch
mkdir -p package/network/ipv6/odhcp6c/patches
wget https://github.com/openwrt/odhcp6c/pull/75.patch -O package/network/ipv6/odhcp6c/patches/75.patch
wget https://github.com/openwrt/odhcp6c/pull/80.patch -O package/network/ipv6/odhcp6c/patches/80.patch
wget https://github.com/openwrt/odhcp6c/pull/82.patch -O package/network/ipv6/odhcp6c/patches/82.patch
wget https://github.com/openwrt/odhcp6c/pull/83.patch -O package/network/ipv6/odhcp6c/patches/83.patch
wget https://github.com/openwrt/odhcp6c/pull/84.patch -O package/network/ipv6/odhcp6c/patches/84.patch
wget https://github.com/openwrt/odhcp6c/pull/90.patch -O package/network/ipv6/odhcp6c/patches/90.patch
# watchcat
echo > ./feeds/packages/utils/watchcat/files/watchcat.config
# 默认开启 Irqbalance
#sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config

### 最后的收尾工作 ###
# Lets Fuck
#mkdir -p package/base-files/files/usr/bin
#cp -rf ../OpenWrt-Add/fuck ./package/base-files/files/usr/bin/fuck
# 生成默认配置及缓存
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-5.15

#LTO/GC
# Grub 2
sed -i 's,no-lto,no-lto no-gc-sections,g' package/boot/grub2/Makefile
# openssl disable LTO
sed -i 's,no-mips16 gc-sections,no-mips16 gc-sections no-lto,g' package/libs/openssl/Makefile
# nginx
sed -i 's,gc-sections,gc-sections no-lto,g' feeds/packages/net/nginx/Makefile
# libsodium
sed -i 's,no-mips16,no-mips16 no-lto,g' feeds/packages/libs/libsodium/Makefile
#exit 0

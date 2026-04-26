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

#修改feeds.conf.default
sed -i 's/src-git/#src-git/g' feeds.conf.default
#添加为github的库
sed -i '$asrc-git packages https://github.com/openwrt/packages.git;openwrt-25.12' feeds.conf.default
sed -i '$asrc-git luci https://github.com/openwrt/luci.git;openwrt-25.12' feeds.conf.default
sed -i '$asrc-git routing https://github.com/openwrt/routing.git;openwrt-25.12' feeds.conf.default
sed -i '$asrc-git telephony https://github.com/openwrt/telephony.git;openwrt-25.12' feeds.conf.default

# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 定义预期的内核版本
SUPPORTED_KERNEL="6.12"

current_version=$(sed -n 's/^KERNEL_PATCHVER:=//p' ./target/linux/rockchip/Makefile) # 如 6.12
if [ -z "${current_version}" ]; then
    echo "Error: Failed to extract KERNEL_PATCHVER from ./target/linux/rockchip/Makefile"
    exit 1
fi
if [[ "${SUPPORTED_KERNEL}" != "${current_version}" ]]; then
    echo "##########
      错误：
      编译的内核版本为 ${current_version} ，
      预期的版本为 ${SUPPORTED_KERNEL}
    ##########"
    exit 1
fi
export KERNEL_VERSION="${SUPPORTED_KERNEL}"
echo "KERNEL_VERSION=${SUPPORTED_KERNEL}" | tee -a "$GITHUB_ENV" 
# 移除 SNAPSHOT 标签
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
sed -i '/CONFIG_BUILDBOT/d' include/feeds.mk
sed -i 's/;)\s*\\/; \\/' include/feeds.mk

### 必要的 Patches ###
# Patch arm64 型号名称
cp -rf ./diydata/PATCH/kernel/arm/* ./target/linux/generic/hack-${KERNEL_VERSION}/
# BBRv3
cp -rf ./diydata/PATCH/kernel/bbr3/* ./target/linux/generic/backport-${KERNEL_VERSION}/

### Fullcone-NAT 部分 ###
# bcmfullcone
cp -rf ./diydata/PATCH/kernel/bcmfullcone/* ./target/linux/generic/hack-${KERNEL_VERSION}/
# set nf_conntrack_expect_max for fullcone
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# FW4
mkdir -p package/network/config/firewall4/patches
cp -f ./diydata/PATCH/pkgs/firewall/firewall4_patches/*.patch ./package/network/config/firewall4/patches/
mkdir -p package/libs/libnftnl/patches
cp -f ./diydata/PATCH/pkgs/firewall/libnftnl/*.patch ./package/libs/libnftnl/patches/
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
mkdir -p package/network/utils/nftables/patches
cp -f ./diydata/PATCH/pkgs/firewall/nftables/*.patch ./package/network/utils/nftables/patches/
# Patch LuCI 以增添 FullCone 开关
pushd feeds/luci
patch -p1 <../.././diydata/PATCH/pkgs/firewall/luci/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
popd

### Shortcut-FE 部分 ###
# Patch Kernel 以支持 Shortcut-FE
cp -rf ./diydata/PATCH/kernel/sfe/* ./target/linux/generic/hack-${KERNEL_VERSION}/
cp -rf ../lede/target/linux/generic/pending-${KERNEL_VERSION}/613-netfilter_optional_tcp_window_check.patch ./target/linux/generic/pending-${KERNEL_VERSION}/613-netfilter_optional_tcp_window_check.patch
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
patch -p1 <../.././diydata/PATCH/pkgs/firewall/luci/0007-luci-app-firewall-add-fullcone6-option-for-nftables-.patch
popd

### Other Kernel Hack 部分 ###
# make olddefconfig
wget -qO - https://github.com/openwrt/openwrt/commit/c21a3570.patch | patch -p1

# IPv6 兼容助手
patch -p1 <./diydata/PATCH/pkgs/odhcp6c/1002-odhcp6c-support-dhcpv6-hotplug.patch
# ODHCPD
rm -rf ./package/network/services/odhcpd
cp -rf ../openwrt_ma/package/network/services/odhcpd ./package/network/services/odhcpd
rm -rf ./package/network/ipv6/odhcp6c
cp -rf ../openwrt_ma/package/network/ipv6/odhcp6c ./package/network/ipv6/odhcp6c
# watchcat
echo > ./feeds/packages/utils/watchcat/files/watchcat.config
# 默认开启 Irqbalance
#sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config

# 使用 TEO CPU 空闲调度器
CONFIG_CONTENT='
CONFIG_CPU_IDLE_GOV_MENU=n
CONFIG_CPU_IDLE_GOV_TEO=y
'
# 查找所有与内核相关的配置文件并将这些配置项追加到文件末尾
find ./target/linux/ -name "config-${KERNEL_VERSION}" | xargs -I{} sh -c "echo '$CONFIG_CONTENT' | tee -a {} > /dev/null"

### 最后的收尾工作 ###
# Lets Fuck
#mkdir -p package/base-files/files/usr/bin
#cp -rf ../OpenWrt-Add/fuck ./package/base-files/files/usr/bin/fuck
# 生成默认配置及缓存
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-${KERNEL_VERSION}

./scripts/feeds update -i
./scripts/feeds install -a

#exit 0

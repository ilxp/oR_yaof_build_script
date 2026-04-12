#!/bin/bash

# --- 配置区域 ---
DO_EDIT=true          # true=直接修改, false=预览模式
FORCE_VERSION=""      # 可选：为特定包强制设置版本号，格式 "包路径=版本号"，可多个用空格隔开
# 示例: FORCE_VERSION="package/network/services/dnsmasq=2.90 package/network/utils/iptables=1.8.8"
# ----------------

echo "开始执行【OpenWrt/Alpine 深度适配修复】..."
echo "针对：PKG_VERSION 移除 ~ 后缀及相关 Makefile 逻辑（智能跳过函数调用）"
echo "---------------------------------------------------"

find . -type f -name "Makefile" | while read -r makefile; do
    
    file_changed=0

    # =======================================================
    # 任务 0: 强制覆盖特定包的版本号（如果配置了）
    # =======================================================
    forced=0
    if [ -n "$FORCE_VERSION" ]; then
        for entry in $FORCE_VERSION; do
            pkg_path="${entry%=*}"
            forced_ver="${entry#*=}"
            if [[ "$makefile" == *"/$pkg_path/Makefile" ]]; then
                echo "[强制覆盖] $makefile"
                if [ "$DO_EDIT" = true ]; then
                    sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$forced_ver/" "$makefile"
                    echo "  -> 版本强制设置为 $forced_ver"
                    file_changed=1
                    forced=1
                fi
                break
            fi
        done
    fi
    if [ $forced -eq 1 ]; then
        # 继续执行后续的 RELEASE 和 HASH 修复，但不再处理 VERSION 清洗
        # 注意：下面还会处理 RELEASE 和 HASH，但跳过 VERSION 的智能清洗
        # 我们通过设置 raw_val 为空来跳过 VERSION 处理
        raw_val=""
    else
        # 提取原始版本号字符串
        raw_val=$(grep "^PKG_VERSION:=" "$makefile" | awk -F':=' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    fi

    # =======================================================
    # 任务 1: 修复 PKG_VERSION (仅处理简单字符串，跳过函数调用)
    # =======================================================
    if [ -n "$raw_val" ]; then
        new_val="$raw_val"
        mode=""

        # --- 安全检查：如果包含 $() 函数调用，则跳过自动清洗 ---
        if echo "$new_val" | grep -q '\$('; then
            echo "[跳过 Version] $makefile (包含 Makefile 函数，跳过清洗)"
            echo "  原始: $raw_val"
            echo "  -> 未修改"
        else
            # 步骤 1: 处理 Makefile 条件逻辑 $(if ...,~...)
            # 这里其实已经在前面过滤掉了包含 $() 的行，但为了安全，仍保留检测
            if echo "$new_val" | grep -q "\$(if.*,.*~"; then
                temp_val=$(echo "$new_val" | sed -E 's/\$\(if[^,]+,[[:space:]]*~.*//')
                if [ "$temp_val" != "$new_val" ]; then
                    new_val="$temp_val"
                    mode="移除逻辑块"
                fi
            fi

            # 步骤 2: 处理普通后缀 (截断 ~ 及其后所有内容)
            if [[ "$new_val" == *"~"* ]]; then
                new_val=$(echo "$new_val" | sed 's/~.*//')
                mode="${mode:+${mode}+}截断后缀"
            fi

            # 步骤 3: 静态版本号常规清洗 (去v，非法字符转点)
            if [[ "$new_val" != *"\$"* ]]; then
                s1=$(echo "$new_val" | sed 's/^[^0-9]*//')
                s2=$(echo "$s1" | sed 's/[^a-zA-Z0-9.]/./g')
                final_static=$(echo "$s2" | sed 's/\.\{2,\}/./g' | sed 's/\.$//')
                if [ -n "$final_static" ] && [ "$new_val" != "$final_static" ]; then
                    new_val="$final_static"
                    mode="${mode:+${mode}+}格式化"
                fi
            fi

            # --- 执行修改 ---
            if [ "$raw_val" != "$new_val" ]; then
                echo "[修复 Version] $makefile"
                echo "  原始: $raw_val"
                echo "  新值: $new_val"
                echo "  操作: $mode"
                if [ "$DO_EDIT" = true ]; then
                    sed -i "s|^PKG_VERSION:=.*|PKG_VERSION:=$new_val|" "$makefile"
                    echo "  -> 已修正"
                    file_changed=1
                else
                    echo "  -> (预览)"
                fi
                echo ""
            fi
        fi
    fi

    # =======================================================
    # 任务 2: 修复 PKG_RELEASE (移除 AUTORELEASE)
    # =======================================================
    if grep -q "^PKG_RELEASE[[:space:]]*:=[[:space:]]*\$(AUTORELEASE)" "$makefile"; then
        echo "[修复 Release] $makefile"
        if [ "$DO_EDIT" = true ]; then
            sed -i 's/^PKG_RELEASE[[:space:]]*:=[[:space:]]*\$(AUTORELEASE)/PKG_RELEASE:=1/' "$makefile"
            echo "  -> 已替换为 1"
            file_changed=1
        fi
        echo ""
    fi

    # =======================================================
    # 任务 3: 修复 PKG_MIRROR_HASH (强制改为 skip)
    # =======================================================
    if grep -q "^PKG_MIRROR_HASH:=" "$makefile" && grep "^PKG_MIRROR_HASH:=" "$makefile" | grep -qv "^PKG_MIRROR_HASH:=skip[[:space:]]*$"; then
        echo "[修复 Mirror Hash] $makefile"
        if [ "$DO_EDIT" = true ]; then
            sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/' "$makefile"
            echo "  -> 已修改为 skip"
            file_changed=1
        fi
        echo ""
    fi

done

echo "处理完成。"

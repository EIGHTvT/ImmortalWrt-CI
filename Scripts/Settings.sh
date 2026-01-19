#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ Build date')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")


WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
#修改WIFI名称
if [ -f "$WIFI_FILE" ]; then
   sed -i "s/ImmortalWrt/$WRT_SSID/g" $WIFI_FILE
   sed -i "s/$WRT_SSID-2.4G/$WRT_SSID/g" $WIFI_FILE
   sed -i "s/$WRT_SSID-5G/${WRT_SSID}_5G/g" $WIFI_FILE
#修改WIFI加密
   sed -i "s/encryption=.*/encryption='psk2+ccmp'/g" $WIFI_FILE
#修改WIFI密码
   sed -i "/set wireless.default_\${dev}.encryption='psk2+ccmp'/a \\\t\t\t\t\tset wireless.default_\${dev}.key='$WRT_WORD'" $WIFI_FILE
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#核心修正：解决网页升级校验报错
MK_FILE="target/linux/mediatek/image/filogic.mk"
DTS_DIR="target/linux/mediatek/dts"

if [ -f "$MK_FILE" ]; then
    echo "正在执行设备 ID 匹配修正..."
    # 物理复制 DTS (解决 No rule to make target 报错)
    # 加上 -f 确保如果文件已存在也能强制覆盖
    if [ -f "$DTS_DIR/mt7981b-cmcc-rax3000m-emmc-mtk.dts" ]; then
        cp -f "$DTS_DIR/mt7981b-cmcc-rax3000m-emmc-mtk.dts" "$DTS_DIR/mt7981b-cmcc-rax3000m-emmc.dts"
    fi

    # 替换 Makefile 中的标识符
    # 这一步会将生成的固件内部文件夹名改为 cmcc,rax3000m-emmc
    sed -i 's/cmcc_rax3000m-emmc-mtk/cmcc,rax3000m-emmc/g' $MK_FILE
    sed -i 's/mt7981b-cmcc-rax3000m-emmc-mtk/mt7981b-cmcc-rax3000m-emmc/g' $MK_FILE
fi

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

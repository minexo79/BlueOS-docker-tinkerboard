#!/usr/bin/env bash

echo "Configuring Asus Tinker Board 2/2S Board..."

VERSION="${VERSION:-master}"
GITHUB_REPOSITORY=${GITHUB_REPOSITORY:-minexo79/BlueOS-docker-tinkerboard}
REMOTE="${REMOTE:-https://raw.githubusercontent.com/${GITHUB_REPOSITORY}}"
ROOT="$REMOTE/$VERSION"
CMDLINE_FILE=/boot/cmdline.txt

# Download, compile, and install spi1 mosi-only device tree overlay for
# neopixel LED on navigator board
# TODO: Test And Verify Can Working Or Not.
echo "- compile spi1 device tree overlay."
DTS_PATH="$ROOT/install/overlays"
DTS_NAME="spi1-led-tinker2"
curl -fsSL -o /tmp/$DTS_NAME $DTS_PATH/$DTS_NAME.dts
dtc -@ -Hepapr -I dts -O dtb -o /boot/overlays/$DTS_NAME.dtbo /tmp/$DTS_NAME

# Remove any configuration related to i2c and spi/spi1 and do the necessary changes for navigator
echo "- Enable I2C, SPI and UART."
for STRING in \
    "#intf:uart0=off" \
    "#intf:uart4=off" \
    "#intf:i2c6=off" \
    "#intf:i2c7=off" \
    "#intf:i2s0=off" \
    "#intf:spi1=off" \
    "#intf:spi5=off" \
    ; do \
    sudo sed -i "/$STRING/d" /boot/config.txt
done
for STRING in \
    "intf:uart0=on" \
    "intf:uart4=on" \
    "intf:i2c6=on" \
    "intf:i2c7=on" \
    "intf:i2s0=on" \
    "intf:spi1=on" \
    "intf:spi5=on" \
    ; do \
    echo "$STRING" | sudo tee -a /boot/config.txt
done

# Check for valid modules file to load kernel modules
if [ -f "/etc/modules" ]; then
    MODULES_FILE="/etc/modules"
else
    MODULES_FILE="/etc/modules-load.d/blueos.conf"
    touch "$MODULES_FILE" || true # Create if it does not exist
fi

echo "- Set up kernel modules. (Ignored)"
# # Remove any configuration or commented part related to the i2c drive
# for STRING in "bcm2835-v4l2" "i2c-bcm2835" "i2c-dev"; do
#     sudo sed -i "/$STRING/d" "$MODULES_FILE"
#     echo "$STRING" | sudo tee -a "$MODULES_FILE"
# done

# Remove any console serial configuration
echo "- Configure serial."
sudo sed -e 's/console=serial[0-9],[0-9]*\ //' -i $CMDLINE_FILE

# Set cgroup, necessary for docker access to memory information
echo "- Enable cgroup with memory and cpu"
grep -q cgroup $CMDLINE_FILE || (
    # Append cgroups on the first line
    sed -i '1 s/$/ cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/' $CMDLINE_FILE
)

echo "- Enable USB OTG as ethernet adapter"
grep -q dwc2 $CMDLINE_FILE || (
    # Append cgroups on the first line
    sed -i '1 s/$/ modules-load=dwc2,g_ether/' $CMDLINE_FILE
)

# Asus Tinkerboard 2 / 2S Ignored
# Update raspberry pi firmware
# this is required to avoid 'i2c transfer timed out' kernel errors
# on older firmware versions
# if grep -q ID=raspbian < /etc/os-release; then
#     RPI_FIRMWARE_VERSION=1340be4
#     if sudo JUST_CHECK=1 rpi-update $RPI_FIRMWARE_VERSION | grep "Firmware update required"; then
#         echo "- Run rpi update."
#         sudo SKIP_WARNING=1 rpi-update $RPI_FIRMWARE_VERSION
#     else
#         echo "- Firmware is up to date."
#     fi
# fi

# Asus Tinkerboard 2 / 2S Ignored
# Force update of bootloader and VL085 firmware on the first boot
echo "- Force update of VL085 and bootloader on first boot. (Ignored)"
# SYSTEMD_EEPROM_UPDATE_FILE="/lib/systemd/system/rpi-eeprom-update.service"
# sudo sed -i '/^ExecStart=\/usr\/bin\/rpi-eeprom-update -s -a$/c\ExecStart=/bin/bash -c "/usr/bin/rpi-eeprom-update -a -d | (grep \\\"reboot to apply\\\" && echo \\\"Rebooting..\\\" && reboot || exit 0)"' $SYSTEMD_EEPROM_UPDATE_FILE
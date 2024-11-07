#!/bin/bash

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
END="\033[0m"

# Function to check if a directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${YELLOW}• $1 already exists. Skipping cloning...${END}"
        return 1
    fi
    return 0
}

# Start
echo -e "${YELLOW}Applying patches and cloning device source...${END}"

# Remove conflicting files
echo -e "${GREEN}• Removing conflicting Pixel headers from hardware/google/pixel/kernel_headers/Android.bp...${END}"
rm -rf hardware/google/pixel/kernel_headers/Android.bp

echo -e "${GREEN}• Removing conflicting LineageOS compat module from hardware/lineage/compat/Android.bp...${END}"
rm -rf hardware/lineage/compat/Android.bp

# Apply Sepolicy fixes
if [ -f device/qcom/sepolicy_vndr/legacy-um/qva/vendor/bengal/legacy-ims/hal_rcsservice.te ]; then
    echo -e "${GREEN}Switching back to legacy imsrcsd sepolicy...${END}"
    rm -rf device/qcom/sepolicy_vndr/legacy-um/qva/vendor/bengal/ims/imsservice.te
    cp device/qcom/sepolicy_vndr/legacy-um/qva/vendor/bengal/legacy-ims/hal_rcsservice.te device/qcom/sepolicy_vndr/legacy-um/qva/vendor/bengal/ims/hal_rcsservice.te
else
    echo -e "${YELLOW}• Please check your ROM source; the file for legacy imsrcsd sepolicy does not exist. Skipping this step...${END}"
fi

# Clone Vendor Sources
if check_dir vendor/xiaomi/spes; then
    git clone https://github.com/halt-spesn/vendor_xiaomi_spes -b 15.0 vendor/xiaomi/spes
fi

# Clone Kernel Sources
    git clone https://github.com/halt-spesn/android_kernel_xiaomi_sm6225 --depth=1 kernel/xiaomi/sm6225 -b master
    cd kernel/xiaomi/sm6225
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s v0.9.5
    cd ../../..
    

# Clone Hardware Sources
if check_dir hardware/xiaomi; then
    echo -e "${GREEN}Cloning hardware sources...${END}"
    git clone https://github.com/halt-spesn/hardware_xiaomi -b vauxite hardware/xiaomi
fi


git clone https://gitlab.com/ThankYouMario/proprietary_vendor_xiaomi_camera.git -b vauxite-sm6225 --depth=1 vendor/xiaomi/camera
git clone https://github.com/halt-spesn/packages_apps_DisplayFeatures.git -b 15.0 --depth=1 packages/apps/DisplayFeatures 
rm -rf packages/services/DeviceAsWebcam
git clone https://github.com/halt-spesn/packages_services_DeviceAsWebcam.git packages/services/DeviceAsWebcam

sed -i 's/return mButtonClicked && !mWasPlaying && isPlaying();/return false;/g' frameworks/base/packages/SystemUI/src/com/android/systemui/media/controls/ui/controller/MediaControlPanel.java
sed -i 's/\("BuildVariant"\s*:\s*"\)user\(".*\)/\1userdebug\2/' build/soong/scripts/gen_build_prop.py
sed -i "215s/{config\['BuildKeys'\]}//" build/soong/scripts/gen_build_prop.py
rm -rf vendor/qcom/opensource/usb
rm -rf vendor/qcom/opensource/power
git clone https://github.com/halt-spesn/android_vendor_qcom_opensource_usb.git -b lineage-22.0 vendor/qcom/opensource/usb
cd vendor/gms
git lfs pull
cd ../..

# End
echo -e "${YELLOW}All patches have been successfully applied; your device sources are now ready!${END}"

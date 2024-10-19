#!/bin/bash

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
END="\033[0m"

# Branches
VENDOR_BRANCH="15.0"

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
    echo -e "${GREEN}Cloning vendor sources from spes-development (branch: ${YELLOW}$VENDOR_BRANCH${GREEN})...${END}"
    git clone https://github.com/halt-spesn/vendor_xiaomi_spes -b $VENDOR_BRANCH vendor/xiaomi/spes
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

#Camera
git clone https://gitlab.com/ThankYouMario/proprietary_vendor_xiaomi_camera.git -b vauxite-sm6225 --depth=1 vendor/xiaomi/camera
git clone https://github.com/halt-spesn/packages_apps_DisplayFeatures.git -b 15.0 --depth=1 packages/apps/DisplayFeatures 

sed -i 's/return mButtonClicked && !mWasPlaying && isPlaying();/return false;/g' frameworks/base/packages/SystemUI/src/com/android/systemui/media/controls/ui/controller/MediaControlPanel.java
sed -i '/build_desc = f".*option.build_id/,+1 s/build_desc = f".*"/build_desc = f"{option.build_id}"/g' build/soong/scripts/buildinfo.py
sed -i '/ro.build.display.id?.*option.build_id/,+5 s/f"ro.build.display.id?.*/f"ro.build.display.id?={option.build_id}")/g' build/soong/scripts/buildinfo.py
sed -i 's/ro.build.display.id?={build_desc}/ro.build.display.id?={build_id}/g' build/soong/scripts/buildinfo.py
sed -i 's/option.build_variant == "user"/option.build_variant == "userdebug"/g' build/soong/scripts/buildinfo.py
grep -q 'Error GetPreviewImageData(StreamInterface* data,' external/piex/src/piex.cc || sed -i '/bool GetDngInformation(StreamInterface\* data, std::uint32_t\* width/ i Error GetPreviewImageData(StreamInterface* data,\n                          PreviewImageData* preview_image_data)\n{\n  return(GetPreviewImageData(data,preview_image_data,nullptr));\n}' external/piex/src/piex.cc
rm -rf vendor/qcom/opensource/commonsys/fm
rm -rf vendor/qcom/opensource/power
cd vendor/gms
git lfs pull
cd ../..

# End
echo -e "${YELLOW}All patches have been successfully applied; your device sources are now ready!${END}"

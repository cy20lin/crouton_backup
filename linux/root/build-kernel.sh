#su - root
apt-get install -y git-core make kernel-package bc
echo 1
cd ~
mkdir -p kernel/version
mkdir -p kernel/kernel
cd kernel/kernel
if test ! -e /root/kernel/kernel/.git
then
    git clone https://chromium.googlesource.com/chromiumos/third_party/kernel . -n
else
    git rev-parse $(uname -r | cut -d- -f3 | tail -c +2) || git pull
fi
git config uploadpack.allowReachableSHA1InWant true




echo 2
UNAME_R=$(uname -r)
mkdir -p ~/kernel/version/${UNAME_R}
cd  ~/kernel/version/${UNAME_R}
rm build.tmp 2>/dev/null
rm source.tmp 2>/dev/null


echo 3
if test ! -e source
then
echo source not exist
mkdir source.tmp
cd source.tmp


git init
git remote add origin https://chromium.googlesource.com/chromiumos/third_party/kernel
git remote add local_origin /root/kernel/kernel
# git fetch --depth 1 local_origin $(uname -r | cut -d- -f3 | tail -c +2)
git fetch --depth 1 local_origin $(cd /root/kernel/kernel 1>/dev/null 2>/dev/null ; uname -r | cut -d- -f3 | tail -c +2 | xargs git rev-parse )
git fetch --depth 1 /root/kernel/kernel $(cd /root/kernel/kernel 1>/dev/null 2>/dev/null ; uname -r | cut -d- -f3 | tail -c +2 | xargs git rev-parse )
git checkout FETCH_HEAD 


echo 5 patch source


modprobe config 2>/dev/null 
cat /proc/config.gz | gzip -d >./chromeos/config/base.config
#zless /proc/config.gz
sed --in-place "s/-dirty/$(uname -r | cut -d- -f3 | tail -c +9)/g" ./scripts/setlocalversion 
sed -i 's/CONFIG_ERROR_ON_WARNING=y/CONFIG_ERROR_ON_WARNING=n/' ./chromeos/config/base.config
sed -i 's/#include <udl_connector.h>/#include "udl_connector.h"/' ./drivers/gpu/drm/udl/udl_connector.c
cd ..
mv source.tmp source
fi


echo 6 prepare build dir
if test ! -e build
then
echo copy files
cp -R source build.tmp
mv build.tmp build
fi


echo 7 confingure
cd build


./chromeos/scripts/prepareconfig chromeos-intel-pineview
yes '' | make oldconfig > /dev/null
make kernelrelease 2>/dev/null | tail -n 1
echo 8 build package
#make
yes '' | sudo make-kpkg --rootcmd fakeroot kernel_image kernel_headers | tee ./build.log

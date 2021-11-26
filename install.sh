#!/bin/bash

# Bash Strict Mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

git clone https://github.com/pcloudcom/console-client.git
cd ./console-client/pCloudCC/ || exit 1

# don't want to compile for Intel Core 2 CPU, using native local machine architecture instead
# see: https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
grep -R core2 | cut -d ':' -f 1 | sort | uniq | while read -r filename; do sed -i "s/-mtune=core2/-mtune=native/g" "$filename"; done

# build steps: https://github.com/pcloudcom/console-client
cd lib/pclsync/ && make clean && make fs
cd ../mbedtls/ && cmake . && make clean && make
cd ../.. && cmake . && make

# necessary, otherwise the following error occurs during package compilation :
# dh_usrlocal: error: debian/pcloudcc/usr/local/bin/pcloudcc is not a directory
echo "override_dh_usrlocal:" >>./debian/rules

# avoids having to run `sudo ldconfig` after installation otherwise the following error occurs:
# pcloudcc: error while loading shared libraries: libpcloudcc_lib.so: cannot open shared object file: No such file or directory
echo "dh_makeshlibs:" >>./debian/rules

# build debian package
apt build-dep -y .
debuild -i -us -uc -b

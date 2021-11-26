# pcloudcc-builder
Script and Dockerfile to build pCloud Console Client package for debian derivatives.

# Usage
```bash
# clone this repo
mkdir /srv/install/
git clone https://github.com/Atlas974/pcloudcc-builder.git /srv/install/pcloudcc
cd /srv/install/pcloudcc

# build package
docker build -t pcloudcc .

# retrieve package
docker run --name pcloudcc pcloudcc
# output:
# /app/console-client/pcloudcc-dbgsym_2.0.1-1_arm64.deb
# /app/console-client/pcloudcc_2.0.1-1_arm64.deb

# copy deb package given in output
docker cp pcloudcc:/app/console-client/pcloudcc_2.0.1-1_arm64.deb .

# install
apt install gdebi-core
gdebi pcloudcc_2.0.1-1_arm64.deb

# enjoy!
```

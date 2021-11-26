FROM debian

# build tools
RUN apt update && apt install -y build-essential fakeroot devscripts cmake

# dependencies required to build pcloudcc
RUN apt install -y zlib1g-dev libboost-system-dev libboost-program-options-dev libpthread-stubs0-dev libfuse-dev libudev-dev

WORKDIR /app
COPY ./install.sh .
RUN ./install.sh

CMD ["/bin/sh", "-c", "/bin/ls /app/console-client/*.deb"]

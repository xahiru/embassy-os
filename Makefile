APPMGR_SRC := $(shell find appmgr/src) appmgr/Cargo.toml appmgr/Cargo.lock
AGENT_SRC := $(shell find agent/src) $(shell find agent/config) agent/stack.yaml agent/package.yaml agent/build.sh

.DELETE_ON_ERROR:

all: embassy.img

embassy.img: buster.img product_key appmgr/target/armv7-unknown-linux-musleabihf/release/appmgr ui/www agent/dist/agent agent/config/agent.service
	./make_image.sh

buster.img:
	wget -O buster.zip https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2020-08-24/2020-08-20-raspios-buster-armhf-lite.zip
	unzip buster.zip
	rm buster.zip
	mv 2020-08-20-raspios-buster-armhf-lite.img buster.img

product_key:
	echo "X\c" > product_key
	cat /dev/random | base32 | head -c11 | tr '[:upper:]' '[:lower:]' >> product_key

appmgr: appmgr/target/armv7-unknown-linux-musleabihf/release/appmgr

appmgr/target/armv7-unknown-linux-musleabihf/release/appmgr: $(APPMGR_SRC)
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)":/home/rust/src start9/rust-arm-cross:latest sh -c "(cd appmgr && cargo build --release --features=production)"
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)":/home/rust/src start9/rust-arm-cross:latest arm-linux-gnueabi-strip appmgr/target/armv7-unknown-linux-gnueabihf/release/appmgr

agent: agent/dist/agent

agent/dist/agent: $(AGENT_SRC)
	(cd agent; ./build.sh)


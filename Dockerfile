FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y --no-install-recommends curl android-sdk &&\
	curl https://cdn.azul.com/zulu/bin/zulu17.34.19-ca-jdk17.0.3-linux_amd64.deb --output /tmp/zulu-jdk-17.deb &&\
	apt install /tmp/zulu-jdk-17.deb &&\
	rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY entrypoint.sh /entrypoint.sh

CMD ["/entrypoint.sh"]

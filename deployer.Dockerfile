FROM debian:stable-slim
LABEL author="KhraD"

# Noninteractive
RUN dpkg-reconfigure debconf --frontend=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends\
    ca-certificates \
    curl \
	unzip \
	git \
	git-lfs \
	jq

#butler
RUN mkdir -p /opt/butler/bin \
  && cd /opt/butler/bin \
  && curl -sL -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default \
  && unzip butler.zip \
  && rm butler.zip \
  && chmod +x butler

ENV PATH="/opt/butler/bin:${PATH}"    

RUN mkdir -p /var/opt/proj

WORKDIR /var/opt/proj

# DESCRIPTION: install essential utils to develop in systemverilog
FROM docker.io/ubuntu:22.04

ARG verilator_version=v5.012
ARG iverilog_version=v12_0
ARG slang_version=v3.0

# set timezone of the image
ENV TZ="Europe/Paris"
RUN ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
RUN echo "$TZ" > /etc/timezone

# set LANG for perl
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y locales

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

# insall essential package for the build env
# already installed tzdata, make
RUN apt update \
    && apt install -y git \
    && apt install -y g++ \
    && apt install -y swig \
    && apt install -y python3 \
    && apt install -y python3-dev \
    && apt install -y python3-pip \
    && apt install -y sysvbanner \
    && pip3 install --no-cache-dir cocotb[bus] \
    && pip3 install --no-cache-dir pytest

RUN cd /tmp/


#   @@@@   @  @    @  @    @  @         @@    @@@@@   @@@@   @@@@@
#  @       @  @@  @@  @    @  @        @  @     @    @    @  @    @
#   @@@@   @  @ @@ @  @    @  @       @    @    @    @    @  @    @
#       @  @  @    @  @    @  @       @@@@@@    @    @    @  @@@@@
#  @    @  @  @    @  @    @  @       @    @    @    @    @  @   @
#   @@@@   @  @    @   @@@@   @@@@@@  @    @    @     @@@@   @    @

# build and install slang
RUN apt install -y cmake \
    && git clone https://github.com/MikePopoloski/slang.git \
    && cd ./slang/ \
    && git checkout ${slang_version} \
    && cmake -B build \
    && cmake --build build \
    && cd ./build/ \
    && ctest --output-on-failure \
    && cd .. \
    && cmake --install build --strip \
    && cd .. \
    && rm -r ./slang/

# build and install verilator
# already installed: perl, libfl2, libfl-dev, zlib1g, zlib1g-dev
RUN apt install -y help2man \
    && apt install -y perl-doc \
    && apt install -y autoconf \
    && apt install -y flex \
    && apt install -y bison \
    && apt install -y ccache \
    && apt install -y numactl \
    && git clone https://github.com/verilator/verilator \
    && cd ./verilator/ \
    && git checkout ${verilator_version} \
    && autoconf \
    && ./configure \
    && make \
    && make test \
    && make install \
    && cd .. \
    && rm -r ./verilator

# build and install iverilog
RUN apt install -y gperf \
    && git clone https://github.com/steveicarus/iverilog.git \
    && cd ./iverilog \
    && git checkout ${iverilog_version} \
    && sh ./autoconf.sh\
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -r ./iverilog


#  @@@@@@   @@@@   @@@@@   @    @    @@    @@@@@  @@@@@@  @@@@@
#  @       @    @  @    @  @@  @@   @  @     @    @       @    @
#  @@@@@   @    @  @    @  @ @@ @  @    @    @    @@@@@   @    @
#  @       @    @  @@@@@   @    @  @@@@@@    @    @       @@@@@
#  @       @    @  @   @   @    @  @    @    @    @       @   @
#  @        @@@@   @    @  @    @  @    @    @    @@@@@@  @    @

# download the sublimetext formater for systemverilog
RUN mkdir /usr/share/s3sv/ \
    && cd /usr/share/s3sv/
RUN apt install -y wget \
    && wget https://raw.githubusercontent.com/TheClams/SystemVerilog/master/verilogutil/verilog_beautifier.py \
    && wget https://raw.githubusercontent.com/TheClams/SystemVerilog/master/verilogutil/verilogutil.py


#  @         @@    @    @   @@@@   @    @    @@     @@@@   @@@@@@
#  @        @  @   @@   @  @    @  @    @   @  @   @    @  @
#  @       @    @  @ @  @  @       @    @  @    @  @       @@@@@
#  @       @@@@@@  @  @ @  @  @@@  @    @  @@@@@@  @  @@@  @
#  @       @    @  @   @@  @    @  @    @  @    @  @    @  @
#  @@@@@@  @    @  @    @   @@@@    @@@@   @    @   @@@@   @@@@@@

#   @@@@   @@@@@@  @@@@@   @    @  @@@@@@  @@@@@
#  @       @       @    @  @    @  @       @    @
#   @@@@   @@@@@   @    @  @    @  @@@@@   @    @
#       @  @       @@@@@   @    @  @       @@@@@
#  @    @  @       @   @    @  @   @       @   @
#   @@@@   @@@@@@  @    @    @@    @@@@@@  @    @

# install hdl_checker
RUN pip3 install --no-cache-dir hdl-checker

# download and install verible
RUN cd /tmp/ \
    && wget https://github.com/chipsalliance/verible/releases/download/v0.0-3296-g0bcc1e5d/verible-v0.0-3296-g0bcc1e5d-linux-static-x86_64.tar.gz \
    && tar zxf verible-v0.0-3296-g0bcc1e5d-linux-static-x86_64.tar.gz \
    && cp -a ./verible-v0.0-3296-g0bcc1e5d/bin/. /usr/bin/ \
    && cp -a ./verible-v0.0-3296-g0bcc1e5d/share/. /usr/share/ \
    && rm -r ./verible-v0.0-3296-g0bcc1e5d \
    && rm ./verible-v0.0-3296-g0bcc1e5d-linux-static-x86_64.tar.gz

# VERIDIAN
# install toolchain for veridian
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y \
    && apt install -y pkg-config \
    && apt install -y libssl-dev \
    && apt install -y libclang-dev
ENV PATH="/config/.cargo/bin:${PATH}"
# build and install veridian
RUN cargo install --root /usr/ --git https://github.com/vivekmalneedi/veridian.git --all-features

# download and install svls
RUN apt install -y unzip \
    && wget https://github.com/dalance/svls/releases/download/v0.2.9/svls-v0.2.9-x86_64-lnx.zip \
    && unzip ./svls-v0.2.9-x86_64-lnx.zip \
    && mv ./svls /usr/bin/ \
    && rm ./svls-v0.2.9-x86_64-lnx.zip \
    && mkdir /usr/share/svlint/
COPY ./.svlint.toml /usr/share/svlint/
ENV SVLINT_CONFIG="/usr/share/svlint/.svlint.toml"
# download and install svlint
RUN wget https://github.com/dalance/svlint/releases/download/v0.8.0/svlint-v0.8.0-x86_64-lnx.zip \
    && unzip ./svlint-v0.8.0-x86_64-lnx.zip \
    && mv ./svlint /usr/bin \
    && rm /svlint-v0.8.0-x86_64-lnx.zip

# download and install universal ctags
RUN git clone https://github.com/universal-ctags/ctags.git \
    && cd ./ctags \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && cd .. \
    && rm -r ./ctags/

# STANDBY for now
# download podman-remote 3.4.4 to be compatible with the podman API on Ubuntu
# RUN mkdir /usr/share/podman/ \
#     && cd /home/ \
#     && wget https://github.com/containers/podman/releases/download/v3.4.4/podman-remote-static.tar.gz \
#     && tar -zxf podman-remote-static.tar.gz \
#     && rm ./podman-remote-static.tar.gz \
#     && mv ./podman-remote-static /usr/share/podman/ \
#     && ln -s /usr/share/podman/podman-remote-static /usr/bin/podman

# need podman to work
# TODO: install asciidoctor convertion kit

# remove cache 
RUN apt clean
RUN rm -rf /var/lib/apt/lists/

# add color to the terminal output
ENV TERM xterm-256color

WORKDIR /workspace

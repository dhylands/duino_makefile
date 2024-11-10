FROM gcc:9.5.0

# You can use `apt list PACKAGE` to determine the exact version.

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y \
        runit \
        sudo \
        python3 \
        python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && pip3 install -U setuptools==59.1.1 \
    && pip3 install --upgrade pip==24.0.0 \
    && pip3 install \
        pyyaml==6.0

RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /root
RUN git clone https://github.com/dhylands/duino_makefile
WORKDIR /root/duino_makefile
ENV PATH="/root/bin:${PATH}"
RUN make TOP_DIR=. BOARD=pico install-tools V=1

# The CLI installs quite a few files into /root/.arduino15 so we make the directory
# group sticky with a group of 'arduino'
ENV ARDUINO_GID=200
RUN groupadd -o -g ${ARDUINO_GID} arduino
RUN mkdir /root/.arduino15
RUN chmod g+rwxs /root/.arduino15
RUN chgrp arduino /root/.arduino15

RUN make TOP_DIR=. BOARD=pico install-cli

RUN ls -l /root /root/bin

WORKDIR /root

COPY entrypoint.sh /usr/bin
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]

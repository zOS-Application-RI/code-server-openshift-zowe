FROM ubuntu:latest
LABEL maintainer="Asihsh K Sahoo <ashissah@in.ibm.com>"

# Docker Container for Ubuntu HElib Base

USER root

# Setup the toolchain
RUN apt update

# set noninteractive installation
RUN export DEBIAN_FRONTEND=noninteractive

# Update the base OS
RUN DEBIAN_FRONTEND=noninteractive apt update
RUN DEBIAN_FRONTEND=noninteractive apt dist-upgrade -y

# Install tzdata package
RUN DEBIAN_FRONTEND=noninteractive apt install -y tzdata
# Set UTC timezone
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

# Install the compilation toolchain we need...
RUN DEBIAN_FRONTEND=noninteractive apt install -y \
    xz-utils         \
    curl             \
    wget             \
    build-essential  \
    git              \
    cmake            \
    m4               \
    file             \
    patchelf         \
    vim
    
RUN apt-get update && \
    apt-get install -y  \
    sudo \
    openssl \
    net-tools \
    git \
    locales \
    curl \
    dumb-init \
    wget && \
    locale-gen en_US.UTF-8 && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Create user coder:coder with no login,
RUN adduser --uid 5000  --gecos "Code Server User" --disabled-login coder \
    && echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
    && chmod g+rw /home/coder \
    # && chmod a+x /opt/exec  \
    && chgrp -R 0 /home/coder \
    && chmod -R g=u /home/coder \
    && chmod g=u /etc/passwd;

WORKDIR /home/coder
USER coder


###############################################################################
###############################################################################
###############################################################################
ENV LANG=en_US.UTF-8 \
    # adding a sane default is needed since we're not erroring out via exec.
    CODER_PASSWORD="coder" \
    SHELL=/bin/bash


# The code-server runs on HTTPS port 8443 so expose it
EXPOSE 8443/tcp

# Set root user for installation
USER root
WORKDIR /root

# Set noninteractive installation
RUN export DEBIAN_FRONTEND=noninteractive

# Install code-server so we can access the IDE from a container context...
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create a directory to hold the VSCode user data
RUN mkdir -p /opt/IBM/IDE-Data
RUN chown -R coder:coder /opt/IBM/IDE-Data

# Create a directory to hold the user's Coder workspace to contain project/sample code
RUN mkdir -p /opt/IBM/Coder-Workspace
RUN chown -R coder:coder /opt/IBM/Coder-Workspace

# Set coder user for the remaining of the installation
USER coder
WORKDIR /home/coder

RUN mkdir /opt/IBM/Coder-Workspace/.vscode
RUN chown -R coder:coder /opt/IBM/Coder-Workspace/.vscode 
COPY ./IDE_Config /opt/IBM/Coder-Workspace/.vscode 


# Install code-server extensions
# RUN code-server --user-data-dir=/opt/IBM/IDE-Data/ --install-extension ibm.zopeneditor --force
# RUN code-server --user-data-dir=/opt/IBM/IDE-Data/ --install-extension zowe.vscode-extension-for-zowe --force
# RUN code-server --user-data-dir=/opt/IBM/IDE-Data/ --install-extension github.vscode-pull-request-github --force

# set code-server to create a self signed cert
# RUN sed -i.bak 's/cert: false/cert: true/' /home/coder/.config/code-server/config.yaml

# Update code-server user settings
# RUN echo "{\"extensions.autoUpdate\": true,\n\"workbench.colorTheme\": \"Dark\"}" > /opt/IBM/IDE-Data/User/settings.json

COPY entrypoint /home/coder
USER 10001
ENTRYPOINT ["/home/coder/entrypoint"]
# Set the default command to launch the code-server project as a web application
CMD ["code-server",  "--bind-addr", "0.0.0.0:8443", "--user-data-dir", "/opt/IBM/IDE-Data/", "/opt/IBM/Coder-Workspace", "--auth", "none", "--disable-telemetry"]
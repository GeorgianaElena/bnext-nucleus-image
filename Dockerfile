# Inherit from an upstream image
FROM quay.io/jupyter/minimal-notebook:latest

USER root

RUN apt-get -y update && apt-get -y install gcc g++ rsync zsh neovim eza caddy jq

USER $NB_UID

# Curvenote
RUN mamba install -y -c conda-forge 'nodejs>=24'
RUN npm install -g curvenote
RUN npm install -g nodemon

# UV
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

USER root

ADD --chown=$NB_UID:$NB_GID bin /opt/repo/bin
ADD --chown=$NB_UID:$NB_GID home-overlay /opt/repo/home-overlay
ADD --chown=$NB_UID:$NB_GID nucleus-env /opt/repo/nucleus-env
ADD --chown=$NB_UID:$NB_GID share /opt/repo/share
ADD --chown=$NB_UID:$NB_GID config /opt/repo/config

RUN ls /opt/repo

# Add directory and correct permissions for additional node installs
RUN mkdir -p /opt/noderoots
RUN chown $NB_UID:users /opt/noderoots

RUN chsh -s /bin/zsh jovyan

USER $NB_UID

RUN git clone --depth=1 https://github.com/mattmc3/antidote.git /home/$NB_UID/.antidote
RUN zsh -ci "source /home/${{ NB_UID }}/.antidote/antidote.zsh && antidote load"

ARG UV_INDEX=https://pypi.org/simple
RUN ~/.local/bin/uv pip install --system -e /opt/repo/nucleus-env --index $UV_INDEX --default-index=https://pypi.org/simple

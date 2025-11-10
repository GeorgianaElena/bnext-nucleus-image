# Inherit from an upstream image
FROM quay.io/jupyter/minimal-notebook:latest

USER root

RUN apt-get -y update && apt-get -y install gcc g++ rsync zsh neovim eza caddy jq

USER $NB_USER

# Curvenote
RUN mamba install -y -c conda-forge 'nodejs>=24'
RUN npm install -g curvenote
RUN npm install -g nodemon

# UV
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

USER root
RUN chsh -s /bin/zsh $NB_USER

USER $NB_USER

ADD --chown=$NB_USER:users . /opt/repo/

ARG UV_INDEX=https://pypi.org/simple
RUN ~/.local/bin/uv pip install --system -e /opt/repo/nucleus-env --index $UV_INDEX --default-index=https://pypi.org/simple

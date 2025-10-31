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
RUN chsh -s /bin/zsh jovyan
USER $NB_USER

RUN git clone --depth=1 https://github.com/mattmc3/antidote.git /home/$NB_USER/.antidote
RUN zsh -ci "source /home/jovyan/.antidote/antidote.zsh && antidote load"

ARG UV_INDEX=https://pypi.org/simple
RUN ~/.local/bin/uv pip install --system -e /opt/repo/nucleus-env --index $UV_INDEX --default-index=https://pypi.org/simple

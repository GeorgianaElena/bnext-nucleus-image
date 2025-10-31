#!/usr/bin/env bash
set -eux

export REPO=/opt/repo
export LOG_FILE=/home/jovyan/work/.log/`date -Iseconds`-setup.log
HOME=/home/jovyan
GIT_REMOTE="https://github.com/bnext-bio/nucleus-jupyterhub.git"
JUPYTER_SETTINGS=/opt/conda/share/jupyter/lab/settings
DEVNOTE_PATH=/home/jovyan/work/devnotes/template


echo "In setup-stub: logging to $LOG_FILE"
mkdir -p `dirname $LOG_FILE`

echo "Running main setup" |& tee ${LOG_FILE}
echo "Setting up environment" |& tee ${LOG_FILE}
echo "Running as: `whoami`" |& tee ${LOG_FILE}
echo "NB_USER: $NB_USER" |& tee ${LOG_FILE}
echo "NB_UID: $NB_UID" |& tee ${LOG_FILE}
echo "NB_GID: $NB_GID" |& tee ${LOG_FILE}
echo "NB_UMASK: $NB_UMASK" |& tee ${LOG_FILE}
echo "UV_INDEX: $UV_INDEX" |& tee ${LOG_FILE}

cd ${REPO}

# Bring down and update our baseline home directory
echo "Updating home directory overlay." |& tee ${LOG_FILE}
rsync -a ${REPO}/home-overlay/ ${HOME}

# Update our jupyter configuration
echo "Updating jupyter configuration" |& tee ${LOG_FILE}
cat ${REPO}/config/jupyter_server_config_additional.py >> ${HOME}/.jupyter/jupyter_server_config.py
mkdir -p ${JUPYTER_SETTINGS}
cp ${REPO}/config/overrides.json ${JUPYTER_SETTINGS}/overrides.json

# Install LSP into node roots using npm
mkdir -p /opt/noderoots
cd /opt/noderoots
npm install --save-dev unified-language-server
cd ${REPO}

# Drop in launcher configuration for the collaboration groups we're a part of
echo "Creating collaboration launchers for user groups" |& tee ${LOG_FILE}
if [[ ! $JUPYTERHUB_USER =~ "-collab" ]]; then
    for group in `curl -H "Authorization: token $JUPYTERHUB_API_TOKEN" $JUPYTERHUB_API_URL/user | jq -r '.groups | join("\n")'`; do
        echo "Creating launcher for group: ${group}" |& tee ${LOG_FILE}
        echo """
- title: \"Collab: ${group}\"
  description: Open the real-time collaboration server for ${group}
  source: /user/${group}-collab
  type: url
  catalog: Nucleus
  args:
    createNewWindow: true
""" > ${HOME}/.local/share/jupyter/jupyter_app_launcher/jp_app_launcher_collab_${group}.yml
    done
else
    echo "Already in collaborative user: not creating launcher" |& tee ${LOG_FILE}
fi

# Add topbar text to indicate the user
echo "Adding topbar configuration" |& tee ${LOG_FILE}
mkdir -p ${HOME}/.jupyter/lab/user-settings/jupyterlab-topbar-text/
TOPBAR_TAG="👤 ${JUPYTERHUB_USER}"
if [[ $JUPYTERHUB_USER =~ "-collab" ]]; then
    TOPBAR_TAG="🌎 ${JUPYTERHUB_USER%-collab}"
fi
echo """{
    \"text\": \"${TOPBAR_TAG}\",
    \"editable\": false
}""" > ${HOME}/.jupyter/lab/user-settings/jupyterlab-topbar-text/plugin.jupyterlab-settings

# Install our key packages
echo "Installing environment packages" |& tee ${LOG_FILE}
~/.local/bin/uv pip install --system -e ${REPO}/nucleus-env --no-progress

# Bring down the curvenote template
echo "Updating curvenote template" |& tee ${LOG_FILE}
if [ -d ${DEVNOTE_PATH} ]; then 
    cd ${DEVNOTE_PATH}
    if [ -d .git.disable ]; then
        mv .git.disable .git
        git pull --ff-only
    fi
else
    git clone --depth=1 https://github.com/antonrmolina/devnote-template.git ${DEVNOTE_PATH}
fi
mv ${DEVNOTE_PATH}/.git ${DEVNOTE_PATH}/.git.disable # Un-repoify it so it can be copied and modified easily.

# Create LSP symlink
echo Creating symlink |& tee ${LOG_FILE}
if [ ! -L ${HOME}/work/.lsp_symlink ]; then
    ln -s / ${HOME}/work/.lsp_symlink
fi

# Create curvenote symlink
echo Linking curvenote config |& tee ${LOG_FILE}
if [ ! -L ${HOME}/.curvenote ]; then
    ln -s ${HOME}/work/.curvenote ~/.curvenote
fi

# Run final shared setup commands
echo Running final setup |& tee ${LOG_FILE}
if [ -f ${HOME}/hub-setup/setup.sh ]; then
    ${HOME}/hub-setup/setup.sh
fi

echo Nucleus environment setup |& tee ${LOG_FILE}

exec "$@"
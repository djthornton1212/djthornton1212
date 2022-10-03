#!/bin/bash

echo "Installing Brew"

/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Installing Brew Casks (GUI related apps):"

brew update

brew install --cask visual-studio-code brackets obsidian powershell iterm2 \
insomnia postman bbedit microsoft-remote-desktop zoom virtualbox airdroid \
teamviewer sensiblesidebuttons docker

echo "Install Brews (Terminal related apps):"

brew install git azure-cli ansible go gh gradle groovy helm iproute2mac jenv \
jq kotlin kubernetes-cli maven nvm pyenv python terraform vault-cli yarn yq

echo "Pip installs:"
python3 -m pip install --user --upgrade pip
python3 -m pip install --user virtualenv




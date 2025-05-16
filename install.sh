#!/bin/bash

set -e

echo "📦 Installing Zsh..."
if ! command -v zsh >/dev/null 2>&1; then
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt update && sudo apt install -y zsh git curl
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install zsh
  else
    echo "Unsupported OS. Please install zsh manually."
    exit 1
  fi
else
  echo "✅ Zsh is already installed."
fi

echo "🌟 Installing oh-my-zsh..."
export RUNZSH=no
export CHSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

echo "⚙️ Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions

echo "🎨 Installing zsh-syntax-highlighting..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting

echo "🛠 Enabling plugins in .zshrc..."
sed -i.bak '/^plugins=/ s/)/ zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

echo "🔄 Sourcing .zshrc..."
source ~/.zshrc

echo "🚀 Changing default shell to zsh (you may be prompted for password)..."
chsh -s "$(which zsh)"

echo "✅ Done! Please restart your terminal to use Zsh."

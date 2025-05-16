#!/bin/bash

set -e

echo "📦 Installing Zsh..."
if ! command -v zsh >/dev/null 2>&1; then
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt update && sudo apt install -y zsh git curl
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install zsh
  else
    echo "❌ Unsupported OS. Please install zsh manually."
    exit 1
  fi
else
  echo "✅ Zsh is already installed."
fi

echo "🚀 Temporarily switching to Zsh to install Oh My Zsh..."

# 将 oh-my-zsh 安装逻辑写入临时文件
cat << 'EOF' > /tmp/zsh_installer.zsh
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
EOF

# 使用 zsh 执行安装逻辑
zsh /tmp/zsh_installer.zsh
rm /tmp/zsh_installer.zsh

echo "🔁 Changing default shell to Zsh..."
chsh -s "$(which zsh)"

echo "✅ All done! Please restart your terminal to start using Zsh."

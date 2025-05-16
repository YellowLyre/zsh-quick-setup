#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 开始针对 Ubuntu/Debian/macOS 安装 Zsh 和常用插件 (尝试新 Oh My Zsh 地址) 🚀"

# --- Helper function to check and run commands ---
run_command() {
    if command -v "$1" &> /dev/null; then
        echo "✅ '$1' 已安装."
        return 0
    else
        echo "📦 准备安装 '$1'..."
        return 1
    fi
}

# --- Detect OS and Package Manager ---
detect_os_package_manager() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            echo "ℹ️ 检测到 Linux (可能为 Ubuntu/Debian)，使用 apt 进行包管理。"
            PACKAGE_MANAGER="apt"
            UPDATE_CMD="sudo apt update"
            INSTALL_CMD="sudo apt install -y"
        elif command -v dnf &> /dev/null; then
             echo "ℹ️ 检测到 Linux (可能为 Fedora/CentOS)，使用 dnf 进行包管理。"
             PACKAGE_MANAGER="dnf"
             UPDATE_CMD="" # dnf install handles updates implicitly
             INSTALL_CMD="sudo dnf install -y"
        elif command -v yum &> /dev/null; then
             echo "ℹ️ 检测到 Linux (可能为 CentOS/RHLE)，使用 yum 进行包管理。"
             PACKAGE_MANAGER="yum"
             UPDATE_CMD="" # yum install handles updates implicitly
             INSTALL_CMD="sudo yum install -y"
        else
            echo "❌ 未检测到支持的 Linux 包管理器 (apt, dnf, yum)。"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo "ℹ️ 检测到 macOS，使用 Homebrew (brew) 进行包管理。"
            PACKAGE_MANAGER="brew"
            UPDATE_CMD="brew update"
            INSTALL_CMD="brew install"
        else
            echo "❌ 在 macOS 上未检测到 Homebrew (brew)。请先安装 Homebrew (https://brew.sh)。"
            exit 1
        fi
    else
        echo "❌ 不支持的操作系统类型 '$OSTYPE'。"
        exit 1
    fi
}

# Call the detection function
detect_os_package_manager

# --- Install Package Function using detected manager ---
install_package() {
    local package_name="$1"
    if run_command "$package_name"; then
        return 0 # Already installed
    fi

    echo "Installing '$package_name' using $PACKAGE_MANAGER..."

    if [ -n "$UPDATE_CMD" ]; then
       $UPDATE_CMD || echo "⚠️ 包管理器更新失败，尝试跳过更新继续安装..."
    fi

    $INSTALL_CMD "$package_name" || {
        echo "❌ 安装 '$package_name' 失败。请手动运行 '$INSTALL_CMD $package_name' 查看错误信息。"
        exit 1
    }

    if command -v "$package_name" &> /dev/null; then
        echo "✅ '$package_name' 安装成功."
    else
        echo "❌ '$package_name' 安装后未找到可执行文件。请手动检查问题。"
        exit 1
    fi
}


# --- 1. Install Git ---
install_package git

# --- 2. Install Zsh ---
install_package zsh

# --- 3. Install Oh My Zsh ---
OHMYZSH_DIR="$HOME/.oh-my-zsh"
# !! UPDATED URL !!
OHMYZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/main/install.sh"

if [ -d "$OHMYZSH_DIR" ]; then
    echo "✅ Oh My Zsh 已安装."
else
    echo "📦 安装 Oh My Zsh (从 $OHMYZSH_INSTALL_URL)..."
    # Set CHSH=no and RUNZSH=no to prevent the Oh My Zsh installer from
    # changing default shell and immediately starting zsh. We handle this later.
    CHSH=no RUNZSH=no sh -c "$(curl -fsSL $OHMYZSH_INSTALL_URL)" || {
        echo "❌ Oh My Zsh 安装脚本下载或执行失败。请检查网络连接或curl，并确认URL ($OHMYZSH_INSTALL_URL) 可访问。"
        exit 1
    }

    if [ -d "$OHMYZSH_DIR" ]; then
        echo "✅ Oh My Zsh 安装成功."
         # Oh My Zsh installer copies .zshrc, let's make sure it exists
        if [ ! -f "$HOME/.zshrc" ]; then
             echo "⚠️ Oh My Zsh 安装成功，但 ~/.zshrc 文件未生成。请检查安装过程。"
             # Attempt to copy template if it exists
             if [ -f "$OHMYZSH_DIR/templates/zshrc.zsh-template" ]; then
                 cp "$OHMYZSH_DIR/templates/zshrc.zsh-template" "$HOME/.zshrc"
                 echo "ℹ️ 已从模板创建 ~/.zshrc 文件。"
             else
                 echo "❌ 无法找到 ~/.zshrc 模板文件。后续配置可能失败。"
                 # Continue, but user will likely need manual intervention
             fi
        fi
    else
        echo "❌ Oh My Zsh 安装失败。请手动检查问题或网络连接。"
        exit 1
    fi
fi


# --- 4. Install zsh-autosuggestions plugin ---
AUTOSUGGESTIONS_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
if [ -d "$AUTOSUGGESTIONS_DIR" ]; then
    echo "✅ zsh-autosuggestions 插件已安装."
else
    echo "📦 安装 zsh-autosuggestions 插件..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR" || echo "⚠️ zsh-autosuggestions 插件安装失败。请手动检查问题。"
fi

# --- 5. Install zsh-syntax-highlighting plugin ---
HIGHLIGHTING_DIR=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
if [ -d "$HIGHLIGHTING_DIR" ]; then
    echo "✅ zsh-syntax-highlighting 插件已安装."
else
    echo "📦 安装 zsh-syntax-highlighting 插件..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HIGHLIGHTING_DIR" || echo "⚠️ zsh-syntax-highlighting 插件安装失败。请手动检查问题。"
fi

# --- 6. Configure plugins in .zshrc ---
ZSHRC="$HOME/.zshrc"
SED_INPLACE=""

# Handle macOS sed syntax
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="-i ''"
else
  SED_INPLACE="-i"
fi

echo "📝 配置 ~/.zshrc 文件..."

if [ -f "$ZSHRC" ]; then
    # Ensure plugins line exists and is not commented out
    if ! grep -q "^\s*plugins=(.*)" "$ZSHRC"; then
        echo "ℹ️ 在 $ZSHRC 中添加 'plugins=(git)' 行..."
        # Add the plugins line after ZSH_THEME= line if it exists, otherwise append
        if grep -q "ZSH_THEME=" "$ZSHRC"; then
            eval "sed $SED_INPLACE '/^ZSH_THEME=/a plugins=(git)' \"$ZSHRC\""
        else
             echo "plugins=(git)" >> "$ZSHRC" # Append if no ZSH_THEME line
        fi
         # Re-check if plugins line is now there
         if ! grep -q "^\s*plugins=(.*)" "$ZSHRC"; then
             echo "❌ 无法在 $ZSHRC 中找到或创建 'plugins=(...)' 行。请手动将 'plugins=(git)' 添加到 $ZSHRC。"
         fi
    fi

    # Add zsh-autosuggestions if not already in the plugins list
    # Check if the plugins line exists before trying to modify it
    if grep -q "^\s*plugins=(.*)" "$ZSHRC" && ! grep -q "zsh-autosuggestions" "$ZSHRC"; then
        echo "    - 添加 zsh-autosuggestions 到 plugins 列表..."
        # Use sed to find the line starting with plugins=( and insert the plugin before the closing )
        eval "sed $SED_INPLACE 's/^plugins=(\(.*\))$/plugins=(\1 zsh-autosuggestions)/' \"$ZSHRC\"" || echo "⚠️ 添加 zsh-autosuggestions 到 plugins 列表失败。请手动检查 $ZSHRC。"
    fi

    # Add zsh-syntax-highlighting if not already in the plugins list
    # Check if the plugins line exists before trying to modify it
    if grep -q "^\s*plugins=(.*)" "$ZSHRC" && ! grep -q "zsh-syntax-highlighting" "$ZSHRC"; then
        echo "    - 添加 zsh-syntax-highlighting 到 plugins 列表..."
        # Use sed to find the line starting with plugins=( and insert the plugin before the closing )
         eval "sed $SED_INPLACE 's/^plugins=(\(.*\))$/plugins=(\1 zsh-syntax-highlighting)/' \"$ZSHRC\"" || echo "⚠️ 添加 zsh-syntax-highlighting 到 plugins 列表失败。请手动检查 $ZSHRC。"
    fi
     echo "✅ 插件配置尝试完成。"

else
    echo "❌ $ZSHRC 文件未找到。Oh My Zsh 安装可能失败或被跳过。请手动配置插件。"
fi

# --- 7. Set Zsh as default shell (important for future sessions) ---
CURRENT_SHELL=$(basename "$SHELL")
ZSH_PATH=$(command -v zsh)

if [ "$CURRENT_SHELL" = "zsh" ]; then
    echo "✅ 你的默认 Shell 已经是 Zsh。"
elif [ -n "$ZSH_PATH" ]; then
    echo "⚙️ 尝试将 Zsh ($ZSH_PATH) 设置为默认 Shell (需要输入用户密码)..."
    # Use `chsh` to change the default shell. Requires user password.
    # Check if running as root, chsh root is different/not needed for user shell
    if [ "$USER" = "root" ]; then
       echo "ℹ️ 检测到当前用户是 root，通常无需为 root 用户更改默认 shell。"
       echo "   如果你需要为其他用户设置 Zsh，请以该用户身份运行脚本。"
       # Optional: offer to change shell for a specific user
       # read -p "请输入要更改shell的用户名 (留空则跳过): " target_user
       # if [ -n "$target_user" ]; then
       #     chsh -s "$ZSH_PATH" "$target_user"
       # fi
    else
        if chsh -s "$ZSH_PATH" "$USER"; then
            echo "✅ Zsh 已设置为你的默认 Shell (对未来登录生效)。"
        else
            echo "❌ 设置默认 Shell 失败。请尝试手动运行 'chsh -s $(command -v zsh)' 并输入密码。"
        fi
    fi
else
    echo "❌ 未找到 Zsh 可执行文件。无法设置默认 Shell。"
fi


# --- 8. Final steps and immediate switch to Zsh ---
echo ""
echo "🎉 安装和配置已完成！"
echo "----------------------------------------------------"
echo "➡️ **现在将立即切换到配置好的 Zsh 环境...**"
echo "----------------------------------------------------"

# Replace the current shell process with a Zsh process.
# This automatically loads the updated .zshrc.
# This must be the very last command that executes successfully.
exec zsh

# This line will only be reached if 'exec zsh' fails
echo "❌ 切换到 Zsh 失败。请手动运行 'exec zsh' 或关闭并重新打开终端。"
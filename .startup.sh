#!/bin/bash

set -eo pipefail

# Check if running in interactive mode
if [ ! -t 0 ]; then
  echo "Error: This script is being run in non-interactive mode."
  echo "This can happen when piping the script directly to bash."
  echo ""
  echo "Please run the script using this command instead:"
  echo 'bash -c "$(curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh)"'
  echo ""
  echo "This will ensure proper TTY handling for sudo prompts and interactive elements."
  exit 1
fi

# ########################################
# INSTALL XCODE COMMAND LINE TOOLS       # 
# ########################################

# Check for Xcode Command Line Tools and install them if not present
xcode-select -p &>/dev/null
if [ $? -ne 0 ]; then
  echo "Installing Xcode Command Line Tools ..."
  xcode-select --install
else
  echo "XCode Command Line Tools already installed"
fi

# Accept Xcode license
echo "before accepting license"
xcode_version=$(xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space:]]+([0-9\.]+)/\1/')
accepted_license_version=$(defaults read /Library/Preferences/com.apple.dt.Xcode 2>/dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2)
if [ "$xcode_version" != "$accepted_license_version" ]; then
  sudo xcodebuild -license accept
fi

# ########################################
# INSTALL HOMEBREW                       #
# ########################################

# Check if Homebrew is installed
is_brew_installed() {
  [ -d "/opt/homebrew" ] || [ -d "/usr/local/Homebrew" ]
}

# Check if Homebrew is in the PATH
is_brew_path_set() {
  command -v brew &>/dev/null
}

# Set Homebrew in the PATH
set_brew_path() {
  if [ -d "/opt/homebrew/bin" ]; then
    # For Apple Silicon Mac
    echo "Apple Silicon Mac detected. Setting Homebrew path..."
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -d "/usr/local/bin" ]; then
    # For Intel Mac
    echo "Intel Mac detected. Setting Homebrew path..."
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# Install Homebrew if it is not installed or not in the PATH
if is_brew_installed && is_brew_path_set; then
  echo "Homebrew is installed and in the PATH."
elif is_brew_installed && ! is_brew_path_set; then
  echo "Homebrew is installed but not in the PATH."
  set_brew_path
else
  echo "Homebrew is not installed. Installing Homebrew..."
  # Check if we're running in a TTY
  if [ -t 0 ]; then
    # Interactive mode - proceed with normal installation
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    # Non-interactive mode - try to install without sudo first
    echo "Running in non-interactive mode. Attempting to install Homebrew without sudo..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # If that fails, provide clear instructions
    if [ $? -ne 0 ]; then
      echo "Error: Homebrew installation failed in non-interactive mode."
      echo "Please run this command instead:"
      echo 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh)"'
      exit 1
    fi
  fi
  set_brew_path
fi

# #########################################################################################
# INSTALL PAM-REATTACH (TMUX), PAM-WATCHID (SUDO WITH WATCH), PAM-TID (SUDO WITH TOUCHID) #
# #########################################################################################

# configure_pam() {
#   # Check if pam-reattach is installed, and install it if not
#   if ! brew list pam-reattach &>/dev/null; then
#     echo "Installing pam-reattach..."
#     brew install pam-reattach
#   else
#     echo "pam-reattach is already installed."
#   fi

#   # Check if /etc/pam.d/sudo_local exists, if not, create it from the template
#   SUDO_LOCAL_FILE="/etc/pam.d/sudo_local"
#   TEMPLATE_FILE="/etc/pam.d/sudo_local.template"

#   if [ ! -f "$SUDO_LOCAL_FILE" ]; then
#     echo "Creating $SUDO_LOCAL_FILE from template..."
#     sudo cp "$TEMPLATE_FILE" "$SUDO_LOCAL_FILE"
#   fi

#   # Define the lines to add
#   LINE_REATTACH="auth       optional       /opt/homebrew/lib/pam/pam_reattach.so"
#   LINE_TOUCHID="auth       sufficient     pam_tid.so"
#   LINE_WATCHID="auth       sufficient     pam_watchid.so"

#   # Read the current file into an array
#   readarray=()
#   while IFS= read -r line; do
#     readarray+=("$line")
#   done < "$SUDO_LOCAL_FILE"

#   # Function to check if a line exists in the file
#   line_exists() {
#     local line="$1"
#     for existing_line in "${readarray[@]}"; do
#       if [[ "$existing_line" == "$line" ]]; then
#         return 0
#       fi
#     done
#     return 1
#   }

#   # Check and add lines if necessary
#   modified=false

#   if ! line_exists "$LINE_REATTACH"; then
#     echo "Adding pam-reattach line..."
#     sudo sed -i.bak "1s|^|$LINE_REATTACH\n|" "$SUDO_LOCAL_FILE"
#     modified=true
#   else
#     echo "pam-reattach is already enabled."
#   fi

#   if ! line_exists "$LINE_TOUCHID"; then
#     echo "Adding pam_tid line..."
#     sudo sed -i.bak "/^#auth       sufficient     pam_tid.so/s|^#||" "$SUDO_LOCAL_FILE"
#     modified=true
#   else
#     echo "pam_tid is already enabled."
#   fi

#   if ! line_exists "$LINE_WATCHID"; then
#     echo "Installing and enabling pam-watchid..."
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/logicer16/pam-watchid/HEAD/install.sh)" -- enable
#     modified=true
#   else
#     echo "pam-watchid is already installed and enabled."
#   fi

#   if [ "$modified" = false ]; then
#     echo "No changes were made, all components are already configured."
#   fi
# }

# Call the function to configure PAM
# configure_pam

# ##########################################
# INSTALL 1PASSWORD AND 1PASSWORD CLI      #
# ##########################################

# Install 1Password
# if [ ! -d "/Applications/1Password.app" ]; then
#   echo "Installing 1Password..."
#   brew install --cask 1password
# else
#   echo "1Password is already installed"
# fi

# if ! command -v op &>/dev/null; then
#   echo "Installing 1Password CLI..."
#   brew install --cask 1password/tap/1password-cli
# fi

# ##########################################
# INSTALL CHEZMOI AND APPLY DOTFILES       #
# ##########################################

# Function to install and apply Chezmoi
install_and_apply_chezmoi() {
  echo "Installing Chezmoi and applying dotfiles..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --ssh --verbose --apply jarodtaylor
}

# Run Chezmoi to apply dotfiles
if command -v chezmoi &>/dev/null && [ -d "$HOME/.local/share/chezmoi" ]; then
  echo "Reapplying chezmoi configuration..."
  chezmoi apply
else
  echo "Chezmoi is not fully set up. Installing and applying configuration..."
  install_and_apply_chezmoi
fi

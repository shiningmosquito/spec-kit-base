#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Core Config
GO_VERSION="1.22.4"
HUGO_VERSION="0.163.1"
INSTALL_DIR="$HOME/.go_local"
PROJECT_BIN_DIR="$(pwd)/bin"

# Visual Output Colors
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"

log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

echo -e "${BOLD}${BLUE}==================================================${RESET}"
echo -e "${BOLD}${BLUE}   Hugo Project Setup & Go Environment Setup      ${RESET}"
echo -e "${BOLD}${BLUE}==================================================${RESET}"

# 1. OS & Architecture Detection
OS_TYPE="$(uname -s)"
ARCH_TYPE="$(uname -m)"

case "$OS_TYPE" in
    Darwin*)
        OS="darwin"
        log_info "Detected Operating System: macOS (Darwin)"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        OS="windows"
        log_info "Detected Operating System: Windows (Git Bash/MSYS)"
        ;;
    Linux*)
        OS="linux"
        log_info "Detected Operating System: Linux"
        ;;
    *)
        OS="unknown"
        log_error "Unsupported Operating System: $OS_TYPE"
        exit 1
        ;;
esac

case "$ARCH_TYPE" in
    x86_64|amd64)
        ARCH="amd64"
        log_info "Detected CPU Architecture: amd64 (x86_64)"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        log_info "Detected CPU Architecture: arm64 (Apple Silicon/AArch64)"
        ;;
    *)
        ARCH="amd64"
        log_warning "Unknown architecture $ARCH_TYPE, defaulting to amd64"
        ;;
esac

# 2. Go Lang Environment Setup
setup_go() {
    log_info "Checking Go installation..."
    
    # Check if go is already available
    if command -v go >/dev/null 2>&1; then
        log_success "Go is already installed: $(go version)"
        return 0
    fi

    log_info "Go is not found in PATH. Initiating local Go v${GO_VERSION} installation..."

    # Determine Go Download URL
    if [ "$OS" = "darwin" ]; then
        GO_URL="https://go.dev/dl/go${GO_VERSION}.darwin-${ARCH}.tar.gz"
    elif [ "$OS" = "windows" ]; then
        GO_URL="https://go.dev/dl/go${GO_VERSION}.windows-${ARCH}.zip"
    elif [ "$OS" = "linux" ]; then
        GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
    fi

    # Create local installation directory
    mkdir -p "$INSTALL_DIR"
    TEMP_GO_FILE="${INSTALL_DIR}/go_temp_archive"

    log_info "Downloading Go from: ${GO_URL}"
    
    # Download with curl
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$TEMP_GO_FILE" "$GO_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$TEMP_GO_FILE" "$GO_URL"
    else
        log_error "Neither curl nor wget is installed. Please install curl or wget."
        exit 1
    fi

    log_info "Extracting Go archive..."
    # Clean up previous install if any
    rm -rf "$INSTALL_DIR/go"

    if [ "$OS" = "windows" ]; then
        # On Windows (Git Bash), extract ZIP
        if command -v unzip >/dev/null 2>&1; then
            unzip -q "$TEMP_GO_FILE" -d "$INSTALL_DIR"
        else
            # Fallback to PowerShell
            powershell -Command "Expand-Archive -Path '$(cygpath -w "$TEMP_GO_FILE")' -DestinationPath '$(cygpath -w "$INSTALL_DIR")' -Force"
        fi
    else
        # On macOS/Linux, extract TAR.GZ
        tar -C "$INSTALL_DIR" -xzf "$TEMP_GO_FILE"
    fi

    # Clean up temp archive
    rm -f "$TEMP_GO_FILE"
    log_success "Go v${GO_VERSION} installed locally at: ${INSTALL_DIR}/go"

    # Configure Shell Profile
    configure_shell_profile
}

configure_shell_profile() {
    GOROOT_VAL="${INSTALL_DIR}/go"
    GOPATH_VAL="${HOME}/go"

    # Detect Shell and determine profile file
    SHELL_NAME="$(basename "$SHELL")"
    PROFILE_FILES=()

    if [ "$SHELL_NAME" = "zsh" ]; then
        PROFILE_FILES=("$HOME/.zshrc")
    elif [ "$SHELL_NAME" = "bash" ]; then
        PROFILE_FILES=("$HOME/.bashrc" "$HOME/.bash_profile")
    else
        PROFILE_FILES=("$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile")
    fi

    MARKER="# >>> Go Lang setup by Hugo Project Setup >>>"
    END_MARKER="# <<< Go Lang setup by Hugo Project Setup <<<"

    # Block content to add
    CONFIG_BLOCK="\n${MARKER}\nexport GOROOT=\"${GOROOT_VAL}\"\nexport GOPATH=\"${GOPATH_VAL}\"\nexport PATH=\"\$GOROOT/bin:\$GOPATH/bin:\$PATH\"\n${END_MARKER}\n"

    configured=false
    for PROFILE in "${PROFILE_FILES[@]}"; do
        # Create profile file if it doesn't exist
        touch "$PROFILE"
        
        # Check if already configured
        if grep -q "$MARKER" "$PROFILE"; then
            log_info "Go paths are already configured in ${PROFILE}"
            configured=true
        else
            log_info "Adding Go configurations to ${PROFILE}..."
            echo -e "$CONFIG_BLOCK" >> "$PROFILE"
            configured=true
        fi
    done

    if [ "$configured" = true ]; then
        log_success "Environment variables successfully added to shell profiles."
        log_warning "Please run: source <your_profile_file> or restart your terminal to update PATH."
        
        # Temporarily export for current script execution
        export GOROOT="$GOROOT_VAL"
        export GOPATH="$GOPATH_VAL"
        export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
    else
        log_error "Could not automatically locate your shell profile. Please add the following to your profile manually:"
        echo -e "${YELLOW}export GOROOT=\"${GOROOT_VAL}\"${RESET}"
        echo -e "${YELLOW}export GOPATH=\"${GOPATH_VAL}\"${RESET}"
        echo -e "${YELLOW}export PATH=\"\$GOROOT/bin:\$GOPATH/bin:\$PATH\"${RESET}"
    fi
}

# 3. Hugo Installation (Local Project Bin)
setup_hugo() {
    log_info "Setting up Hugo v${HUGO_VERSION} locally for project..."
    
    mkdir -p "$PROJECT_BIN_DIR"
    
    # Determine Hugo Download URL
    if [ "$OS" = "darwin" ]; then
        HUGO_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_darwin-universal.pkg"
        HUGO_BIN="hugo"
    elif [ "$OS" = "windows" ]; then
        HUGO_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_windows-amd64.zip"
        HUGO_BIN="hugo.exe"
    elif [ "$OS" = "linux" ]; then
        HUGO_URL="https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-${ARCH}.tar.gz"
        HUGO_BIN="hugo"
    fi

    # Check if Hugo already exists in local bin
    if [ -f "${PROJECT_BIN_DIR}/${HUGO_BIN}" ]; then
        # Check if version matches
        CURRENT_HUGO_VER="$("${PROJECT_BIN_DIR}/${HUGO_BIN}" version 2>/dev/null | awk '{print $2}' || true)"
        if [[ "$CURRENT_HUGO_VER" == *"$HUGO_VERSION"* ]]; then
            log_success "Hugo v${HUGO_VERSION} is already available at local bin: ${PROJECT_BIN_DIR}/${HUGO_BIN}"
            return 0
        fi
        log_warning "Found Hugo local version: ${CURRENT_HUGO_VER}. Replacing with v${HUGO_VERSION}."
    fi

    TEMP_HUGO_FILE="${PROJECT_BIN_DIR}/hugo_temp_archive"
    log_info "Downloading Hugo from: ${HUGO_URL}"

    # Download Hugo
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$TEMP_HUGO_FILE" "$HUGO_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$TEMP_HUGO_FILE" "$HUGO_URL"
    else
        log_error "Neither curl nor wget is installed."
        exit 1
    fi

    log_info "Extracting Hugo..."
    if [ "$OS" = "windows" ]; then
        TEMP_EXTRACT_DIR="${PROJECT_BIN_DIR}/temp_hugo_extract"
        mkdir -p "$TEMP_EXTRACT_DIR"
        
        if command -v unzip >/dev/null 2>&1; then
            unzip -q "$TEMP_HUGO_FILE" -d "$TEMP_EXTRACT_DIR"
        else
            powershell -Command "Expand-Archive -Path '$(cygpath -w "$TEMP_HUGO_FILE")' -DestinationPath '$(cygpath -w "$TEMP_EXTRACT_DIR")' -Force"
        fi
        
        mv "${TEMP_EXTRACT_DIR}/${HUGO_BIN}" "${PROJECT_BIN_DIR}/${HUGO_BIN}"
        rm -rf "$TEMP_EXTRACT_DIR"
    elif [ "$OS" = "darwin" ]; then
        TEMP_EXTRACT_DIR="${PROJECT_BIN_DIR}/temp_hugo_extract"
        rm -rf "$TEMP_EXTRACT_DIR"
        
        log_info "Expanding macOS pkg using pkgutil..."
        pkgutil --expand-full "$TEMP_HUGO_FILE" "$TEMP_EXTRACT_DIR"
        
        # Locate the hugo binary in the expanded directory and move it
        FOUND_HUGO="$(find "$TEMP_EXTRACT_DIR" -name "hugo" -type f | head -n 1)"
        if [ -n "$FOUND_HUGO" ]; then
            mv "$FOUND_HUGO" "${PROJECT_BIN_DIR}/${HUGO_BIN}"
        else
            log_error "Could not find 'hugo' binary in the expanded pkg files."
            exit 1
        fi
        
        rm -rf "$TEMP_EXTRACT_DIR"
    else
        # On Linux, extract TAR.GZ
        tar -xzf "$TEMP_HUGO_FILE" -C "$PROJECT_BIN_DIR" "$HUGO_BIN"
    fi

    rm -f "$TEMP_HUGO_FILE"
    chmod +x "${PROJECT_BIN_DIR}/${HUGO_BIN}"
    
    log_success "Hugo v${HUGO_VERSION} successfully set up at: ${PROJECT_BIN_DIR}/${HUGO_BIN}"
}

# Run setup tasks
setup_go
setup_hugo

echo -e "${BOLD}${GREEN}==================================================${RESET}"
echo -e "${BOLD}${GREEN}   Setup Completed Successfully!                  ${RESET}"
echo -e "${BOLD}${GREEN}==================================================${RESET}"
echo -e "You can now run Hugo commands using the local script commands:"
echo -e "  - Dev Server:  ${BOLD}./bin/hugo server${RESET} or ${BOLD}npm run dev${RESET}"
echo -e "  - Build Site:  ${BOLD}./bin/hugo${RESET} or ${BOLD}npm run build${RESET}"
echo -e "If Go was just installed, please run: ${BOLD}source ~/.zshrc${RESET} (or your shell's profile file) to enable 'go'."

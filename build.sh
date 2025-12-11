#!/bin/bash
SCRIPT_DIR="$(dirname $(readlink -fq $0))"

# update git submodules if exists
git submodule update --init --recursive || true

# check and install requirements and install Samsung's ndk
install_requirements() {
    local packages=('rsync' 'curl')
    local missing_pkgs=()

    if ! command -v dpkg &>/dev/null; then
        echo "This script is intended to run in Ubuntu/Debian-based Distributions only !"
        exit 1
    fi

    for pkg in "${packages[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        local unique_pkgs=$(echo "${missing_pkgs[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
        echo "Installing required package(s): ${unique_pkgs}"
        sudo apt update && sudo apt install -y "${unique_pkgs}"
    else
        echo "All required packages are already installed."
    fi

    # Init Samsung's ndk
    if [[ ! -d "${SCRIPT_DIR}/kernel/prebuilts" || ! -d "${SCRIPT_DIR}/prebuilts" ]]; then
        echo -e "[INFO] Cloning Samsung's NDK..."
        curl -LO "https://github.com/ravindu644/android_kernel_a166p/releases/download/toolchain/toolchain.tar.gz" || {
            echo "Failed to download Samsung's NDK. Please check your internet connection and try again."
            exit 1
        }
        tar -xf toolchain.tar.gz && rm toolchain.tar.gz
        cd "${SCRIPT_DIR}"
    fi
}

install_requirements

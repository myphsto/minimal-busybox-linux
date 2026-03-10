#!/bin/bash

# Shared QEMU configuration logic for minimal-busybox-linux

get_ovmf_path() {
    # Allow environment override
    if [ -n "$OVMF_PATH" ]; then
        echo "$OVMF_PATH"
        return
    fi

    # Try to find Homebrew prefix dynamically on macOS
    local brew_prefix=""
    if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null; then
        brew_prefix=$(brew --prefix)
    fi

    local common_paths=(
        "/usr/share/ovmf/OVMF.fd"
        "/usr/share/edk2-ovmf/x64/OVMF.fd"
    )

    if [ -n "$brew_prefix" ]; then
        common_paths+=("${brew_prefix}/share/qemu/edk2-x86_64-code.fd")
    fi

    # Common fallbacks if brew is not in path or not used
    common_paths+=(
        "/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
        "/usr/local/share/qemu/edk2-x86_64-code.fd"
    )

    for path in "${common_paths[@]}"; do
        if [ -n "$path" ] && [ -f "$path" ]; then
            echo "$path"
            return
        fi
    done
    
    # Fallback to a standard location if nothing found
    echo "/usr/share/ovmf/OVMF.fd"
}

get_accel_opts() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ "$(uname -m)" == "x86_64" ]]; then
            echo "-accel hvf -cpu host"
        else
            echo "-cpu max"
        fi
    else
        [ -e /dev/kvm ] && echo "-enable-kvm -cpu host" || echo "-cpu max"
    fi
}

get_display_opts() {
    local mode=$1
    if [ "$mode" = "headless" ]; then
        echo "-nographic -serial stdio -monitor none"
    else
        [[ "$OSTYPE" == "darwin"* ]] && echo "-display cocoa" || echo "-display gtk"
    fi
}

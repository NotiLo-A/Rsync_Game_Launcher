#!/usr/bin/env bash

_ssh_get_pubkey() {
    local key_cyg="$1"
    cat "${key_cyg}.pub"
}

run_ssh_host_config_as_admin() {
    local BASH_WIN
    BASH_WIN="$DATA_DIR\cygwin64\bin\bash.exe"

    powershell -NoProfile -Command \
        "Start-Process -FilePath '$BASH_WIN' -ArgumentList '-lc','/bin/ssh-host-config' -Verb RunAs -Wait"
}

_ssh_ensure_key() {
    local key_cyg="$1"
    local key_dir
    key_dir="$(dirname "$key_cyg")"
    mkdir -p "$key_dir"

    if [ ! -f "$key_cyg" ]; then
        local sys_user key_date key_comment
        sys_user="$(whoami)"
        key_date="$(date -Iseconds)"
        key_comment="${sys_user}@${key_date}"

        ssh-keygen -t ed25519 -C "$key_comment" -f "$key_cyg" -N ""
        return 10   # keygen
    fi

    chmod 0700 "$key_cyg"
    return 0
}

_ssh_check_access() {
    local key="$1"
    local server_ip="$2"
    local port="$3"

    local err
    err=$(ssh -v \
        -i "$key" \
        -T \
        -p "$port" \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=5 \
        -o BatchMode=yes \
        hita@"$server_ip" true 2>&1)

    local rc=$?

    if [ "$rc" -eq 0 ]; then
        return 0
    fi

    if grep -qi "permission denied" <<< "$err"; then
        return 10  # auth failed
    fi

    if grep -qiE "connection refused|no route to host|operation timed out|could not resolve" <<< "$err"; then
        return 20  # unreachable
    fi

    return 30  # unknown ssh failure
}


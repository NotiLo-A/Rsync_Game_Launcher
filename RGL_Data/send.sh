#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/bin:$PATH"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/ui.sh"
source "$SCRIPT_DIR/ssh_check.sh"

: "${NOTICE_ON_CONNECTION:?Missing NOTICE_ON_CONNECTION}"
: "${SERVER_IP:?Missing SERVER_IP}"
: "${LOCAL_FORWARD_PORT:?Missing LOCAL_FORWARD_PORT}"
: "${REMOTE_FORWARD_PORT:?Missing REMOTE_FORWARD_PORT}"
: "${SERVER_SSH_PORT:?Missing SERVER_SSH_PORT}"

SSH_KEY="$DATA_DIR/ssh/send/id_ed25519"

_ssh_ensure_key "$SSH_KEY" || {
    rc=$?
    if [[ "$rc" -eq 10 ]]; then
        ui_warn "SSH key not found. Generated new key."
        ui_box "Add this public key to authorized_keys:"
        ui_print "$(_ssh_get_pubkey "$SSH_KEY")"
        ui_pause
    fi
}

# run_ssh_host_config_as_admin

ssh_cmd=(
    ssh -v -N
    -R "0.0.0.0:${REMOTE_FORWARD_PORT}:localhost:${LOCAL_FORWARD_PORT}"
    -i "$SSH_KEY"
    -o IdentitiesOnly=yes
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -p "$SERVER_SSH_PORT"
    "root@${SERVER_IP}"
)

if [ "$NOTICE_ON_CONNECTION" = "true" ]; then
    "${ssh_cmd[@]}" 2>&1 | powershell -NoProfile -Command '
        $input | ForEach-Object {
            Write-Host $_
            if ($_ -match "originator ([0-9.]+) port ([0-9]+)") {
                New-BurntToastNotification -Text "New connection [LT]", ("IP: " + $matches[1] + " Port: " + $matches[2])
            }
        }
    '
else
    "${ssh_cmd[@]}"
fi

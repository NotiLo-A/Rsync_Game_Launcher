#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:$PATH"

# Globals

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/ui.sh"
source "$SCRIPT_DIR/ssh_check.sh"

# Error handling

error_trap() {
    local exit_code=$?
    ui_error "Unexpected failure at line $1 (exit: $exit_code)"
    ui_pause
    exit "$exit_code"
}
trap 'error_trap $LINENO' ERR
# ^ Whats that ^

fatal() {
    ui_error "$1"
    ui_pause
    exit 1
}

require_env() {
    local name="$1"
    [[ -n "${!name:-}" ]] || fatal "Missing required env variable: $name"
}

# Environment validation


require_env DATA_DIR
require_env SERVER_IP
require_env REMOTE_FORWARD_PORT
require_env SSH_USER
require_env SOURCE
require_env DESTINATION
require_env GAME_BIN

# Path normalization

SSH_KEY="$DATA_DIR/ssh/receive/id_ed25519"
PARTIAL_DIR="$DATA_DIR/Partial"
KNOWN_HOSTS="$DATA_DIR/ssh/known_hosts"
LOG_DIR="$DATA_DIR/Logs"
RSYNC_LOG_FILE="$LOG_DIR/rsync-$(date +%F_%H-%M-%S).log" # was called "LOG_FILE"

mkdir -p "$PARTIAL_DIR" "$LOG_DIR" "$DATA_DIR/ssh"
touch "$KNOWN_HOSTS"
chmod 0600 "$KNOWN_HOSTS"

# SSH

handle_ssh_error() {
    local rc="$1"

    case "$rc" in
        10)
            ui_warn "Key does not pass."
            ui_box "Ask your host to authorize this key:"
            ui_print "$(_ssh_get_pubkey "$SSH_KEY")"
            ;;
        20)
            ui_error "Server unreachable or tunnel not active."
            ;;
        *)
            ui_error "Unknown SSH error ($rc)."
            ;;
    esac

    ui_pause
    exit 1
}

_ssh_ensure_key "$SSH_KEY" || {
    rc=$?
    if [[ "$rc" -eq 10 ]]; then
        ui_warn "SSH key not found. Generated new key."
        ui_box "Add this public key to authorized_keys:"
        ui_print "$(_ssh_get_pubkey "$SSH_KEY")"
        ui_pause
        exit 1
    fi
    handle_ssh_error "$rc"
}

ui_success "SSH key ready."

_ssh_check_access "$SSH_KEY" "$SERVER_IP" "$REMOTE_FORWARD_PORT" \
    || handle_ssh_error "$?"

ui_success "SSH access confirmed."

# Rsync

ui_info "Connecting to $SERVER_IP:$REMOTE_FORWARD_PORT (reverse tunnel)"
ui_info "Remote path: $SOURCE"
ui_info "Local path:  $DESTINATION"

SSH_CMD=(
    ssh
    -i "$SSH_KEY"
    -T
    -p "$REMOTE_FORWARD_PORT"
    -o IdentitiesOnly=yes
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile="$KNOWN_HOSTS"
    -o ConnectTimeout=5
)

set +e

rsync \
    --archive \
    --compress \
    --times \
    --delete \
    --modify-window=2 \
    --info=progress2 \
    --stats \
    --itemize-changes \
    --human-readable \
    --log-file="$RSYNC_LOG_FILE" \
    --no-owner \
    --no-group \
    --no-perms \
    --include="plugins/***" \
    --include="config/***" \
    --include="core/***" \
    --include="patchers/***" \
    --exclude="*" \
    -e "${SSH_CMD[*]}" \
    $SSH_USER@$SERVER_IP:"$SOURCE/" \
    "$DESTINATION"

rc=$?
set -e

# Rsync result handling

case "$rc" in
    0)
        ui_success "Sync completed successfully."
        read -r -p "Press Enter to play..."
        cygstart "$GAME_BIN"
        exit 0
        ;;
    12)
        ui_error "Tunnel unreachable (remote host offline?)."
        ;;
    23)
        ui_warn "Partial transfer due to error."
        ;;
    24)
        ui_warn "Partial transfer (vanished files)."
        ;;
    255)
        ui_error "SSH connection failed (tunnel not active?)."
        ;;
    *)
        ui_error "Rsync failed with exit code $rc."
        ;;
esac

ui_pause
exit "$rc"

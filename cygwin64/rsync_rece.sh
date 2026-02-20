#!/bin/bash
set -e

DATA_DIR=$(cygpath -u "$DATA_DIR_WIN")
LOCAL_DIR=$(cygpath -u "$LOCAL_DIR_WIN")
REMOTE_PATH=$(cygpath -u "$REMOTE_PATH_WIN")


rsync -v --progress --stats --itemize-changes --human-readable \
  --log-file="$DATA_DIR/Log.txt" \
  --recursive --checksum --compress --times \
  --delete --delete-during --partial \
  --partial-dir="$DATA_DIR/Partial" \
  --include="BepInEx/" \
  --include="BepInEx/plugins/***" \
  --include="BepInEx/core/***" \
  --include="BepInEx/patchers/***" \
  --exclude="*" \
  -e "ssh -i \"$DATA_DIR/ssh/id_ed25519\" -T -v -p $SERVER_PORT \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null" \
  hita@$SERVER_IP:"$REMOTE_PATH" \
  "$LOCAL_DIR"


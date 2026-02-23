<div align="center">

# Rsync Game Launcher

**RGL** — peer-to-peer game file synchronization over reverse SSH tunnels and rsync.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue)](https://www.microsoft.com/windows)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%2F%20Cygwin-green)](https://www.cygwin.com/)
[![SSH](https://img.shields.io/badge/Powered%20by-OpenSSH%20%2B%20Rsync-orange)](https://www.openssh.com/)

<br/>

<a href="#how-it-works"><kbd> <br> How It Works <br> </kbd></a>&ensp;
<a href="#quick-start"><kbd> <br> Quick Start <br> </kbd></a>&ensp;
<a href="#sender-setup"><kbd> <br> Sender Setup <br> </kbd></a>&ensp;
<a href="#receiver-setup"><kbd> <br> Receiver Setup <br> </kbd></a>&ensp;
<a href="#server-setup"><kbd> <br> Server Setup <br> </kbd></a>&ensp;
<a href="#ssh-key-authentication"><kbd> <br> SSH Keys <br> </kbd></a>&ensp;
<a href="#configuration"><kbd> <br> Configuration <br> </kbd></a>&ensp;

</div>

---

## How It Works

```
  ┌──────────────────────────────────────────────────────────────┐
  │                                                              │
  │  [SENDER PC]  ──── reverse SSH tunnel ────►  [SERVER/VPS]    │
  │  (Windows / Cygwin)                          (Linux)         │
  │                                                   ▲          │
  │                                                   │          │
  │  [RECEIVER PC] ────────── rsync over SSH ─────────┘          │
  │  (Windows / Cygwin)                                          │
  │                                                              │
  └──────────────────────────────────────────────────────────────┘
```

1. The **Sender** opens a reverse SSH tunnel to a public VPS (`send.sh`), forwarding their local SSH port through a configured remote port — no port forwarding on the sender's router required.
2. The **Receiver** connects to that VPS port via rsync (`receive.sh`) and mirrors the files locally.
3. Partial transfers are saved in `Partial/` and automatically resumed on the next run.
4. After sync completes, RGL prompts to launch the game.

The sender runs a local `sshd` via Cygwin. The VPS acts purely as an intermediary — it forwards the tunnel, not the files. Rsync traffic goes directly through the tunnel: `Receiver → VPS:REMOTE_FORWARD_PORT → Sender`.

> Originally built for sharing [Lethal Company](https://store.steampowered.com/app/1966720/Lethal_Company/) mod profiles via [Gale](https://github.com/Kesomannen/gale), but works for any directory sync use case.

## Requirements

| Role | Requirements |
|---|---|
| **Sender** | Windows, Cygwin with `openssh` + `rsync` + `cygrunsrv`, access to a VPS |
| **Receiver** | Windows only — Cygwin is bundled, no installation needed |
| **Server** | Any Linux VPS with SSH access |

## Quick Start

```bat
LethaLauncherData\LethaLauncher.bat send
LethaLauncherData\LethaLauncher.bat receive
```

Edit `config.sh` once before running. See setup sections below for first-time configuration.

## Sender Setup

The sender needs a system-wide Cygwin installation to run `sshd`. Receivers use the bundled Cygwin and need no additional setup.

### Step 1 — Install Cygwin

Download from [cygwin.com/install.html](https://cygwin.com/install.html) (default path: `C:\cygwin64`) and include these packages:

| Package | Purpose |
|---|---|
| `openssh` | SSH server and client |
| `rsync` | File synchronization |
| `cygrunsrv` | Run Cygwin daemons as Windows services |

### Step 2 — Configure sshd

Open **Cygwin64 Terminal as Administrator** and run:

```bash
ssh-host-config
```

```
Should StrictModes be used?          → no
Install sshd as a service?           → yes
Enter the value of CYGWIN for the daemon[]: → (press Enter)
```

### Step 3 — Start the SSH Service

```bash
net start sshd
```

### Step 4 — Authorize the Receiver

The receiver shares `ssh/receive/id_ed25519.pub` with you. Add it to `~/.ssh/authorized_keys` on your machine.

### Step 5 — (Optional) Connection Notifications

```powershell
Install-Module BurntToast -Scope CurrentUser -Force
```

Set `NOTICE_ON_CONNECTION=true` in `config.sh` to get a Windows toast notification whenever a receiver connects.

## Receiver Setup

No system configuration required. Cygwin is bundled in `LethaLauncherData/cygwin64/`.

1. Edit `config.sh` with the correct paths and server details.
2. Share `ssh/receive/id_ed25519.pub` with the sender so they can authorize you.
3. Run:

```bat
LethaLauncherData\LethaLauncher.bat receive
```

On each run, RGL will: check/generate SSH keys (`ssh_check.sh`), connect to the VPS, rsync the files (resuming from `Partial/` if needed), and offer to launch the game.

## Server Setup

The VPS needs two options enabled in `/etc/ssh/sshd_config`:

```
AllowTcpForwarding yes
GatewayPorts yes
```

`GatewayPorts yes` is required to expose the reverse tunnel port to external connections, not just localhost. Restart SSH after editing:

```bash
systemctl restart ssh
```

## SSH Key Authentication

RGL manages SSH keys automatically via `ssh_check.sh` — no manual `ssh-keygen` needed. Two separate key pairs are maintained, one per role:

```
LethaLauncherData/ssh/
├── known_hosts
├── send/
│   ├── id_ed25519        ← Sender's private key
│   └── id_ed25519.pub    ← Add to VPS authorized_keys
└── receive/
    ├── id_ed25519        ← Receiver's private key
    └── id_ed25519.pub    ← Share with the sender
```

**Key exchange workflow:**

```
Receiver                                    Sender
   │                                           │
   │── share receive/id_ed25519.pub ──────────►│
   │                                           │── add key to ~/.ssh/authorized_keys
   │                                           │── LethaLauncher.bat send
   │── LethaLauncher.bat receive ──────────────│
   │◄──────────── files synced ────────────────│
```

## Configuration

All settings are in `LethaLauncherData/config.sh`:

```bash
# ── Common ────────────────────────────────────────────────────────────────────
DATA_DIR="LethaLauncherData"
SERVER_IP=xx.xx.xx.xx            # Public IP or domain of your VPS
REMOTE_FORWARD_PORT=2222         # Port the reverse tunnel is exposed on
SSH_USER=user                    # SSH user on the VPS

# ── Receiver ──────────────────────────────────────────────────────────────────
SOURCE_WINDOWS="C:\\Path\\To\\Your\\Files"
SOURCE="$(cygpath -u "$SOURCE_WINDOWS")"   # Auto-converted to Unix path
DESTINATION="BepInEx"                      # Local sync destination
GAME_BIN="Lethal Company.exe"              # Executable launched after sync

# ── Sender ────────────────────────────────────────────────────────────────────
SERVER_SSH_PORT=22               # SSH port of the VPS
LOCAL_FORWARD_PORT=22            # Local port exposed through the tunnel
NOTICE_ON_CONNECTION=true        # Toast notification on receiver connect
```

## Project Structure

```
rsync-game-launcher/
├── Rsync Game Launcher.lnk        ← Shortcut (pre-configured for send mode)
├── LICENSE
├── README.md
│
└── LethaLauncherData/
    ├── LethaLauncher.bat          ← Entry point: accepts 'send' or 'receive'
    ├── send.sh                    ← Opens reverse SSH tunnel to VPS
    ├── receive.sh                 ← Runs rsync sync, then prompts game launch
    ├── ssh_check.sh               ← SSH key generation and validation
    ├── ui.sh                      ← CLI UI helpers
    ├── config.sh                  ← All user configuration
    │
    ├── cygwin64/                  ← Bundled Cygwin (receiver use only)
    ├── Logs/                      ← session logs (rsync only)
    ├── Partial/                   ← Incomplete downloads, resumed automatically
    │
    └── ssh/
        ├── known_hosts
        ├── send/
        │   ├── id_ed25519
        │   └── id_ed25519.pub
        └── receive/
            ├── id_ed25519
            └── id_ed25519.pub
```

## License

[GNU General Public License v3.0](LICENSE)

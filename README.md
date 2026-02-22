<div align="center">

# Rsync Game Launcher 

**RGL** — a high-performance peer-to-peer game file synchronization tool built on reverse SSH tunneling and rsync.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue)](https://www.microsoft.com/windows)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%2F%20Cygwin-green)](https://www.cygwin.com/)
[![SSH](https://img.shields.io/badge/Powered%20by-OpenSSH%20%2B%20Rsync-orange)](https://www.openssh.com/)
<br/>

<br/>

<a href="#-how-it-works"><kbd> <br> How It Works <br> </kbd></a>&ensp;&ensp;
<a href="#-quick-start"><kbd> <br> Quick Start <br> </kbd></a>&ensp;&ensp;
<a href="#-sender-setup"><kbd> <br> Sender Setup <br> </kbd></a>&ensp;&ensp;
<a href="#-receiver-setup"><kbd> <br> Receiver Setup <br> </kbd></a>&ensp;&ensp;
<a href="#%EF%B8%8F-server-setup"><kbd> <br> Server Setup <br> </kbd></a>&ensp;&ensp;
<a href="#-ssh-key-authentication"><kbd> <br> SSH Keys <br> </kbd></a>&ensp;&ensp;
<a href="#%EF%B8%8F-configuration"><kbd> <br> Configuration <br> </kbd></a>&ensp;&ensp;

</div>



## ✨ Features

- **Reverse SSH Tunneling** — the sender punches through NAT without any port forwarding
- **rsync-powered** — only transfers changed files; supports resuming partial downloads
- **Self-contained** — ships with a bundled Cygwin environment, no system-wide installation needed for receivers
- **Key-based auth** — auto-generates separate SSH key pairs for send and receive roles
- **Post-sync launcher** — automatically offers to launch the game after sync completes
- **Connection notifications** — optional Windows toast notifications when a client connects
- **Full logging** — all sessions are saved to the `Logs/` folder
- **Simple flag-based modes** — `send` and `receive` via a single batch file
<br><br>
## 📐 How It Works

```
  ┌──────────────────────────────────────────────────────────────┐
  │                                                              │
  │  [SENDER PC]  ──── reverse SSH tunnel ────►  [SERVER/VPS]    │
  │  (Windows / Cygwin)                          (Linux)         │
  │                                                   ▲          │
  │                                                   │          │
  │                                                   │          │
  │  [RECEIVER PC] ────────── rsync over SSH ─────────┘          │
  │  (Windows / Cygwin)                                          │
  │                                                              │
  └──────────────────────────────────────────────────────────────┘
```

1. The **Sender** opens a reverse SSH tunnel to a public VPS, forwarding their local SSH through a chosen remote port.
2. The **Receiver** connects to that VPS port via rsync and mirrors the files locally.
3. After synchronization, RGL offers to launch the game automatically.
4. Partial transfers are saved in `Partial/` and resumed on the next run.

> RGL was originally built for sharing Lethal Company mods (via [Gale mod manager](https://github.com/Kesomannen/gale)) between friends, but works for any file synchronization use case.
<br><br>
## ⚡ Quick Start

**For the Receiver** — just double-click the shortcut:

```
LethaLauncher.lnk   ← double-click this
```

**Or run manually:**

```bat
LethaLauncherData\LethaLauncher.bat send
LethaLauncherData\LethaLauncher.bat receive
```

Configure `config.sh` once and you're good to go.
<br><br>

## 📤 Sender Setup

The sender needs Cygwin installed system-wide to run an SSH daemon. Receivers use the bundled Cygwin and need no extra setup.

### Step 1 — Install Cygwin

Download and install from [cygwin.com/install.html](https://cygwin.com/install.html)

> Default install path: `C:\cygwin64`

During installation, select the following packages:

| Package | Purpose |
|---|---|
| `openssh` | SSH server and client |
| `rsync` | File synchronization |
| `cygrunsrv` | Run Cygwin daemons as Windows services |

### Step 2 — Configure the SSH Daemon

Open **Cygwin64 Terminal as Administrator** and run:

```bash
ssh-host-config
```

Answer the prompts as follows:

```
Query: Should StrictModes be used? (yes/no):          → no
Query: Install sshd as a service?  (yes/no):          → yes
Query: Enter the value of CYGWIN for the daemon[]:    → (press Enter)
```

### Step 3 — Start the SSH Service

```bash
net start sshd
```

### Step 4 — (Optional) Connection Notifications

Get a Windows toast notification whenever a receiver connects:

```powershell
Install-Module BurntToast -Scope CurrentUser -Force
```

Then set `NOTICE_ON_CONNECTION=true` in your `config.sh`.

### Step 5 — Add the Receiver's Public Key

The receiver shares their `ssh/receive/id_ed25519.pub` with you. Add it to your `~/.ssh/authorized_keys` so they can authenticate and connect.
<br><br>

## 📥 Receiver Setup

Receivers need **no special system configuration**. Cygwin is bundled inside `LethaLauncherData/cygwin64/`.

1. Edit `LethaLauncherData/config.sh` with the correct paths and server details.
2. Get your public key (`ssh/receive/id_ed25519.pub`) to the sender — they'll authorize it on their end.
3. Double-click `LethaLauncher.lnk` or run:

```bat
LethaLauncherData\LethaLauncher.bat receive
```

RGL will:
1. Check / generate SSH keys via `ssh_check.sh`
2. Connect to the VPS via rsync on the configured tunnel port
3. Mirror all files (resuming any partial transfer from `Partial/`)
4. Prompt you to launch the game
<br><br>

## 🖥️ Server Setup

You need a publicly accessible Linux VPS acting as the SSH tunnel intermediary.

### Step 1 — Edit SSH Config

```bash
nano /etc/ssh/sshd_config
```

Set the following:

```
AllowTcpForwarding yes
GatewayPorts yes
```

### Step 2 — Restart SSH

```bash
systemctl restart ssh
```

> ⚠️ `GatewayPorts yes` is required to make the reverse tunnel port accessible from outside the server — not just from localhost.
<br><br>

## 🔑 SSH Key Authentication

RGL manages SSH keys automatically via `ssh_check.sh`. Two separate key pairs are maintained — one for each role:

```
LethaLauncherData/ssh/
├── known_hosts
├── send/
│   ├── id_ed25519        ← Sender's private key
│   └── id_ed25519.pub    ← Add this to the VPS authorized_keys
└── receive/
    ├── id_ed25519        ← Receiver's private key
    └── id_ed25519.pub    ← Share this with the sender
```

**Typical workflow:**

```
Receiver                                  Sender
   │                                         │
   │─── share receive/id_ed25519.pub ───────►│
   │                                         │─── adds key to C:\cygwin64\home\USER\.ssh\authorized_keys
   │                                         │─── LethaLauncher.bat send
   │─── LethaLauncher.bat receive ───────────│
   │◄──────────── files synced ──────────────│
```

Keys are generated automatically on first run — no manual `ssh-keygen` needed.
<br><br>

## 🛠️ Configuration

All settings live in `LethaLauncherData/config.sh`:

```bash
# ── Common ───────────────────────────────────────────────────────────────────
DATA_DIR="LethaLauncherData"
SERVER_IP=xx.xx.xx.xx            # Public IP or domain of your VPS
REMOTE_FORWARD_PORT=2222         # Port the reverse tunnel will be exposed on
SSH_USER=hita                    # SSH user on the VPS

# ── Receiver specific ─────────────────────────────────────────────────────────
SOURCE_WINDOWS="C:\\Users\\Hita\\AppData\\Roaming\\com.kesomannen.gale\\lethal-company\\profiles\\mainV1\\BepInEx"
SOURCE="$(cygpath -u "$SOURCE_WINDOWS")"   # Auto-converted to Unix path
DESTINATION="BepInEx"                      # Local destination folder
GAME_BIN="Lethal Company.exe"             # Executable to launch after sync

# ── Sender specific ───────────────────────────────────────────────────────────
SERVER_SSH_PORT=22               # SSH port of the VPS
LOCAL_FORWARD_PORT=22            # Local port to expose through the tunnel
NOTICE_ON_CONNECTION=true        # Windows toast when a receiver connects
```

## 📁 Project Structure

```
Rsync_Game_Launcher/
│
├── LethaLauncher.lnk              ← Shortcut (pre-configured for send mode)
├── LICENSE
├── README.md
│
└── LethaLauncherData/
    ├── LethaLauncher.bat          ← Entry point: pass 'send' or 'receive'
    ├── send.sh                    ← Sender logic (opens reverse SSH tunnel)
    ├── receive.sh                 ← Receiver logic (rsync sync + game launch)
    ├── ssh_check.sh               ← SSH key generation and validation
    ├── ui.sh                      ← CLI UI helpers
    ├── config.sh                  ← All user configuration
    │
    ├── cygwin64/                  ← Bundled Cygwin environment (receivers only)
    ├── Logs/                      ← Session logs
    ├── Partial/                   ← Incomplete downloads (auto-resumed on next run)
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

## 📦 Requirements

| Role | Requirements |
|---|---|
| **Sender** | Windows, Cygwin with `openssh` + `rsync` + `cygrunsrv`, access to a VPS |
| **Receiver** | Windows only — Cygwin is bundled, just configure `config.sh` |
| **Server** | Any Linux VPS with SSH, `AllowTcpForwarding yes` and `GatewayPorts yes` |


## 🚀 Usage Reference

| Command | Mode | Description |
|---|---|---|
| `LethaLauncher.lnk` | Send | Double-click shortcut — opens reverse SSH tunnel |
| `LethaLauncher.bat send` | Send | Manually start sender mode |
| `LethaLauncher.bat receive` | Receive | Sync files from sender, then optionally launch game |


## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request


## 📄 License

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.

```
Rsync Game Launcher — P2P game file sync via reverse SSH and rsync
Copyright (C) 2026 NotiLo-A

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```

----

<div align="center">
          <!--for all my friends :3-->
Made with ❤️ for the Lethal Company modding community

*and anyone else who wants to share files the hacker way*

</div>

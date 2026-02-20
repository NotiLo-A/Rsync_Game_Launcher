# Common

DATA_DIR="LethaLauncherData"

SERVER_IP=167.99.141.95
REMOTE_FORWARD_PORT=2222 # TODO: rename
SSH_USER=hita

# Recieve specific

SOURCE_WINDOWS="C:\\Users\\Hita\\AppData\\Roaming\\com.kesomannen.gale\\lethal-company\\profiles\\mainV1\\BepInEx"
SOURCE="$(cygpath -u "$SOURCE_WINDOWS")"
DESTINATION="BepInEx"

GAME_BIN="Lethal Company.exe"

# Send specific

SERVER_SSH_PORT=22
LOCAL_FORWARD_PORT=22

NOTICE_ON_CONNECTION=true

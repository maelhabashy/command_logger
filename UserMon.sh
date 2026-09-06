#!/bin/bash
#############################################################################
# User & Docker Monitor - Full Setup Script (v3)
#
# What this installs:
#   1. auditd-based, EVENT-DRIVEN (not polling) monitoring of every command
#      run by every user, via a real-time audit plugin. Kernel-level,
#      survives su/sudo, can't be bypassed by clearing bash history or
#      switching shells.
#   2. Login / logout tracking for all users (same real-time plugin).
#   3. Docker / container activity logging (start, stop, create, remove,
#      exec into container, kill, restart, etc.), streamed live.
#   4. A human-readable, color-coded "pretty" log for each category.
#   5. Custom log rotation: every log file rotates at 3MB, old files are
#      renamed with a timestamp and NEVER deleted.
#
# Usage:
#   sudo bash user_monitor_full_setup.sh              # install / re-install
#   sudo bash user_monitor_full_setup.sh --uninstall   # remove everything
#############################################################################

set -e

# ---------------------------------------------------------------------------
# Color helpers (console output)
# ---------------------------------------------------------------------------
C_RESET='\033[0m'
C_INFO='\033[1;34m'      # blue
C_OK='\033[1;32m'        # green
C_WARN='\033[1;33m'      # yellow
C_ERR='\033[1;31m'       # red
C_TITLE='\033[1;36m'     # cyan

info()  { echo -e "${C_INFO}==>${C_RESET} $1"; }
ok()    { echo -e "${C_OK}[OK]${C_RESET} $1"; }
warn()  { echo -e "${C_WARN}[WARN]${C_RESET} $1"; }
err()   { echo -e "${C_ERR}[ERROR]${C_RESET} $1"; }
title() { echo -e "${C_TITLE}$1${C_RESET}"; }

LOG_DIR="/var/log/user_monitor"
RULES_FILE="/etc/audit/rules.d/user-monitor.rules"
PARSER_AWK="/usr/local/bin/user-monitor-parser.awk"
PARSER_WRAPPER="/usr/local/bin/user-monitor-pretty.sh"
DOCKER_SCRIPT="/usr/local/bin/docker-monitor-pretty.sh"
DOCKER_SERVICE="/etc/systemd/system/docker-monitor-pretty.service"
AUDITD_CONF_BACKUP="/etc/audit/auditd.conf.bak-user-monitor"

# ===========================================================================
# UNINSTALL MODE
# ===========================================================================
if [[ "$1" == "--uninstall" ]]; then
    if [[ $EUID -ne 0 ]]; then err "Run with sudo."; exit 1; fi
    info "Removing Docker monitor service..."
    systemctl disable --now docker-monitor-pretty.service 2>/dev/null || true
    rm -f "$DOCKER_SERVICE" "$DOCKER_SCRIPT"

    info "Removing audit plugin (both possible locations)..."
    rm -f /etc/audit/plugins.d/user-monitor.conf
    rm -f /etc/audisp/plugins.d/user-monitor.conf
    rm -f "$PARSER_AWK" "$PARSER_WRAPPER"

    info "Removing audit rule..."
    rm -f "$RULES_FILE"

    if [[ -f "$AUDITD_CONF_BACKUP" ]]; then
        info "Restoring original auditd.conf (backed up before this script edited it)..."
        cp -p "$AUDITD_CONF_BACKUP" /etc/audit/auditd.conf
        rm -f "$AUDITD_CONF_BACKUP"
    else
        warn "No backup of auditd.conf found; leaving its rotation settings as they are."
    fi

    systemctl daemon-reload
    systemctl restart auditd 2>/dev/null || service auditd restart 2>/dev/null || true
    augenrules --load 2>/dev/null || true

    warn "Log files under $LOG_DIR and /var/log/audit were NOT deleted (kept for audit purposes)."
    ok "Uninstall complete."
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
   err "This script must be run as root (use sudo)."
   exit 1
fi

mkdir -p "$LOG_DIR"

# ===========================================================================
# PART 1 - Install packages
# ===========================================================================
title "PART 1: Package installation"

install_required() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq
        apt-get install -y auditd gawk jq
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y audit gawk jq
    elif command -v yum >/dev/null 2>&1; then
        yum install -y audit gawk jq
    else
        err "Could not detect a supported package manager (apt/dnf/yum). Install auditd, gawk and jq manually."
        exit 1
    fi
}

install_optional_legacy_plugin_pkg() {
    # Only needed on older distros with a separate audispd daemon.
    # Allowed to fail silently: modern auditd doesn't ship/need it.
    if command -v apt-get >/dev/null 2>&1; then
        apt-get install -y audispd-plugins >/dev/null 2>&1 || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y audispd-plugins >/dev/null 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
        yum install -y audispd-plugins >/dev/null 2>&1 || true
    fi
}

info "Installing required packages (auditd, gawk, jq)..."
install_required
ok "Required packages installed."

info "Attempting optional legacy audispd-plugins package (safe to fail on modern systems)..."
install_optional_legacy_plugin_pkg

if ! command -v gawk >/dev/null 2>&1; then
    err "gawk is required but was not found after installation. Aborting."
    exit 1
fi

# ===========================================================================
# PART 2 - Audit rules (command watching only -- no -D/-b, see header notes)
# ===========================================================================
title "PART 2: Audit rules"
info "Writing audit rule (additive only, does not reset other rules)..."
cat > "$RULES_FILE" << 'RULES_EOF'
# Log every command executed by any user (including after su/sudo).
# Deliberately does NOT include -D or -b here: this file is merged with
# any other files in /etc/audit/rules.d/ by augenrules, and resetting
# rules from a single file in that directory could wipe out unrelated
# audit configuration on the system.
-a always,exit -F arch=b64 -S execve -k cmd_monitor
-a always,exit -F arch=b32 -S execve -k cmd_monitor
RULES_EOF

systemctl enable auditd >/dev/null 2>&1 || true
systemctl restart auditd || service auditd restart
augenrules --load 2>/dev/null || auditctl -R "$RULES_FILE"

if auditctl -l 2>/dev/null | grep -q cmd_monitor; then
    ok "Audit rule verified as active (key: cmd_monitor)."
else
    warn "Could not verify the audit rule is loaded. Check 'auditctl -l' manually (may require a reboot on some systems)."
fi

# ---------------------------------------------------------------------------
# Native auditd rotation for the RAW audit trail: 3MB per file, keep every
# old file (legal/forensic copy, separate from our pretty log).
# ---------------------------------------------------------------------------
info "Configuring raw audit.log rotation (3MB per file, never delete)..."
[[ -f "$AUDITD_CONF_BACKUP" ]] || cp -p /etc/audit/auditd.conf "$AUDITD_CONF_BACKUP"
sed -i \
  -e 's/^max_log_file *=.*/max_log_file = 3/' \
  -e 's/^num_logs *=.*/num_logs = 9999/' \
  -e 's/^max_log_file_action *=.*/max_log_file_action = ROTATE/' \
  /etc/audit/auditd.conf
grep -q '^max_log_file '        /etc/audit/auditd.conf || echo "max_log_file = 3"            >> /etc/audit/auditd.conf
grep -q '^num_logs '            /etc/audit/auditd.conf || echo "num_logs = 9999"              >> /etc/audit/auditd.conf
grep -q '^max_log_file_action ' /etc/audit/auditd.conf || echo "max_log_file_action = ROTATE" >> /etc/audit/auditd.conf
ok "Raw audit trail rotation configured."

# ===========================================================================
# PART 3 - Real-time plugin: parses events as auditd emits them (no polling)
# ===========================================================================
title "PART 3: Real-time command + login/logout parser"
info "Installing gawk event parser (long-running, event-driven, no repeated forking)..."
cat > "$PARSER_AWK" << 'AWK_EOF'
# Reads raw audit events fed by auditd/audispd on stdin and writes a
# color-coded, human-readable log with custom 3MB rotation (old files
# kept, never deleted). Designed to run as ONE persistent process --
# steady-state operation forks nothing except `mv`, and only at actual
# rotation time, so the parser does not generate self-noise in the very
# log it maintains.
#
# Known limitation: EXECVE arguments containing non-printable bytes are
# hex-encoded by the kernel audit subsystem instead of quoted; this
# parser passes those through as raw hex rather than decoding them, since
# that is a rare edge case for normal shell commands. Similarly, a command
# with an extremely large number of/very long arguments can be split by
# the kernel across multiple EXECVE records (a2[0]=, a2[1]=, ...); this
# parser reconstructs the common single-record case and will show a
# truncated command for that rare split-record case rather than failing.

BEGIN {
    LOG_DIR = "/var/log/user_monitor"
    PRETTY_LOG = LOG_DIR "/activity.log"
    MAX_SIZE = 3*1024*1024
    ENABLE_COLOR_LOGS = 1

    if (ENABLE_COLOR_LOGS) {
        CLR_CMD    = "\033[0;36m"
        CLR_LOGIN  = "\033[0;32m"
        CLR_LOGOUT = "\033[0;33m"
        CLR_RESET  = "\033[0m"
    } else {
        CLR_CMD = ""; CLR_LOGIN = ""; CLR_LOGOUT = ""; CLR_RESET = ""
    }

    system("mkdir -p \"" LOG_DIR "\"")

    # Build uid -> username map once, from /etc/passwd, so we never have
    # to fork `id`/`getent` per event.
    while ((getline pline < "/etc/passwd") > 0) {
        split(pline, f, ":")
        uidname[f[3]] = f[1]
    }
    close("/etc/passwd")

    cur_size = 0
    szcmd = "stat -c%s \"" PRETTY_LOG "\" 2>/dev/null"
    szcmd | getline cur_size
    close(szcmd)
    if (cur_size == "") cur_size = 0
    cur_size += 0

    pending_count = 0
}

function now_ts() {
    return strftime("%Y-%m-%d %H:%M:%S", systime())
}

function rotate() {
    stamp = strftime("%Y%m%d_%H%M%S", systime())
    newname = PRETTY_LOG
    sub(/\.log$/, "_" stamp ".log", newname)
    system("mv \"" PRETTY_LOG "\" \"" newname "\" 2>/dev/null")
    cur_size = 0
}

function uname_of(uid) {
    if (uid in uidname) return uidname[uid]
    if (uid == "unset" || uid == "4294967295" || uid == "-1") return "unset(non-login-process)"
    return uid
}

function write_line(s) {
    if (cur_size >= MAX_SIZE) rotate()
    print s >> PRETTY_LOG
    close(PRETTY_LOG)
    cur_size += length(s) + 1
}

function get_quoted_field(line, name,    val) {
    if (match(line, name "=\"[^\"]*\"")) {
        val = substr(line, RSTART, RLENGTH)
        sub("^" name "=\"", "", val)
        sub("\"$", "", val)
        return val
    }
    return ""
}

function get_field(line, name,    val) {
    val = get_quoted_field(line, name)
    if (val != "") return val
    if (match(line, name "=[^ ]+")) {
        val = substr(line, RSTART, RLENGTH)
        sub("^" name "=", "", val)
        return val
    }
    return ""
}

function msg_id(line,    m) {
    if (match(line, /msg=audit\([0-9.]+:[0-9]+\)/)) {
        m = substr(line, RSTART, RLENGTH)
        sub(/^msg=audit\(/, "", m)
        sub(/\)$/, "", m)
        return m
    }
    return ""
}

# ---- Command execution: correlate SYSCALL (has auid + key) with the
#      matching EXECVE (has the actual argv) via their shared audit id ----
/^type=SYSCALL/ {
    if (index($0, "key=\"cmd_monitor\"") == 0 && index($0, "key=cmd_monitor") == 0) next
    id = msg_id($0)
    if (id == "") next
    pending_auid[id] = get_field($0, "auid")
    pending_count++
    # Safety valve: if EXECVE records are ever lost/reordered, entries
    # here never get cleared by the normal EXECVE handler below. This
    # bounds the table instead of leaking memory over weeks of uptime.
    if (pending_count > 5000) {
        delete pending_auid
        pending_count = 0
    }
    next
}

/^type=EXECVE/ {
    id = msg_id($0)
    if (id == "" || !(id in pending_auid)) next

    cmdstr = ""
    i = 0
    while (match($0, "a" i "=\"[^\"]*\"") || match($0, "a" i "=[0-9A-Fa-f]+")) {
        val = substr($0, RSTART, RLENGTH)
        sub("^a" i "=", "", val)
        gsub(/^"|"$/, "", val)
        cmdstr = (cmdstr == "") ? val : cmdstr " " val
        i++
        if (i > 64) break   # safety cap against malformed/huge lines
    }
    if (cmdstr != "") {
        user = uname_of(pending_auid[id])
        line = CLR_CMD "[" now_ts() "] | user: " user " | cmd: " cmdstr CLR_RESET
        write_line(line)
    }
    delete pending_auid[id]
    pending_count--
    next
}

# ---- Login / logout ----
# NOTE (bug found in testing): raw (non "-i" interpreted) USER_LOGIN /
# USER_LOGOUT records do NOT reliably carry an "acct=" field -- that is
# something ausearch -i synthesizes. The real, always-present identity
# field on these records is the top-level "auid=" (same field used for
# command attribution), so we resolve the user the same way here.
/^type=USER_LOGIN/ || /^type=USER_LOGOUT/ {
    uid = get_field($0, "auid")
    if (uid == "") next
    user = uname_of(uid)

    addr = get_field($0, "addr")
    if (addr == "" || addr == "?") addr = "local"
    res = get_field($0, "res")
    gsub(/'/, "", res)   # raw records wrap the trailing field in a bare
                         # single quote with no space (...res=success'),
                         # which get_field's non-quoted match otherwise
                         # swallows as part of the value
    if (res == "") res = "unknown"

    is_login = (index($0, "type=USER_LOGIN") == 1)
    clr   = is_login ? CLR_LOGIN : CLR_LOGOUT
    label = is_login ? "LOGIN" : "LOGOUT"

    block = clr "+------------------------------------------+\n"
    block = block "| " label "\n"
    block = block "|   user   : " user "\n"
    block = block "|   from   : " addr "\n"
    block = block "|   result : " res "\n"
    block = block "|   time   : " now_ts() "\n"
    block = block "+------------------------------------------+" CLR_RESET
    write_line(block)
    next
}
AWK_EOF
ok "Parser installed at $PARSER_AWK"

info "Installing launcher wrapper..."
cat > "$PARSER_WRAPPER" << WRAP_EOF
#!/bin/bash
# Thin launcher: auditd/audispd execs this file as the plugin process.
# exec replaces this shell with gawk directly -- no extra child process.
exec /usr/bin/gawk -f "$PARSER_AWK"
WRAP_EOF
chmod +x "$PARSER_WRAPPER"
ok "Launcher installed at $PARSER_WRAPPER"

# ---------------------------------------------------------------------------
# Register the plugin with auditd, auto-detecting modern vs legacy layout.
# ---------------------------------------------------------------------------
info "Registering audit plugin..."
if [[ -d /etc/audisp/plugins.d ]] && [[ ! -d /etc/audit/plugins.d ]]; then
    PLUGIN_DIR="/etc/audisp/plugins.d"
    LEGACY=1
else
    mkdir -p /etc/audit/plugins.d
    PLUGIN_DIR="/etc/audit/plugins.d"
    LEGACY=0
fi

cat > "$PLUGIN_DIR/user-monitor.conf" << PLUGIN_EOF
active = yes
direction = out
path = $PARSER_WRAPPER
type = always
args =
format = string
PLUGIN_EOF

grep -q '^plugin_dir' /etc/audit/auditd.conf 2>/dev/null || echo "plugin_dir = /etc/audit/plugins.d" >> /etc/audit/auditd.conf

systemctl restart auditd || service auditd restart
if [[ "$LEGACY" -eq 1 ]]; then
    systemctl restart audispd 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# SELinux (RHEL-family: CloudLinux 8, AlmaLinux 10, etc.). Ubuntu doesn't
# need this -- AppArmor doesn't confine auditd's plugin execution the way
# SELinux's auditd_t domain does, and getenforce simply won't exist there.
# ---------------------------------------------------------------------------
if command -v getenforce >/dev/null 2>&1; then
    SELINUX_MODE=$(getenforce)
    info "SELinux detected (mode: $SELINUX_MODE). Applying default file contexts to plugin files..."
    command -v restorecon >/dev/null 2>&1 && restorecon -Rv "$PARSER_WRAPPER" "$PARSER_AWK" "$LOG_DIR" >/dev/null 2>&1
fi

sleep 1

if pgrep -f "gawk -f $PARSER_AWK" >/dev/null 2>&1; then
    ok "Real-time parser is running (plugin active in: $PLUGIN_DIR)."
else
    warn "Could not confirm the parser process is running."
    if [[ "${SELINUX_MODE:-}" == "Enforcing" ]] && command -v ausearch >/dev/null 2>&1; then
        info "SELinux is enforcing -- checking for a related AVC denial..."
        AVC_HITS=$(ausearch -m avc -ts recent 2>/dev/null | grep -c "user-monitor\|auditd_t" || true)
        if [[ "${AVC_HITS:-0}" -gt 0 ]]; then
            err "SELinux is blocking the plugin. Relevant denial(s):"
            ausearch -m avc -ts recent 2>/dev/null | grep "user-monitor\|auditd_t" | tail -5
            echo ""
            echo "To generate a policy allowing this specific action, run:"
            echo "  ausearch -m avc -ts recent | audit2allow -M user-monitor-plugin"
            echo "  semodule -i user-monitor-plugin.pp"
            echo "(Do this instead of disabling SELinux -- it grants only what's needed.)"
        else
            warn "No AVC denial found yet. Check: auditctl -s ; and that 'plugin_dir' in /etc/audit/auditd.conf matches $PLUGIN_DIR"
        fi
    else
        warn "Check: auditctl -s ; and that 'plugin_dir' in /etc/audit/auditd.conf matches $PLUGIN_DIR"
    fi
fi

# ===========================================================================
# PART 4 - Docker / container activity logging (event-driven, unchanged
#           design from v2, only the "triggered_by" match pattern is fixed
#           to match the new pretty-log format)
# ===========================================================================
title "PART 4: Docker / container activity logging"
if command -v docker >/dev/null 2>&1; then
    info "Docker detected. Installing container activity logger..."

    cat > "$DOCKER_SCRIPT" << 'DOCKER_EOF'
#!/bin/bash
# Streams "docker events" in real time and writes a human-readable,
# color-coded log for container lifecycle activity (create, start, stop,
# kill, die, restart, remove, exec, etc.), with custom 3MB rotation
# (old files are kept, never deleted).
#
# Uses `jq` when available for reliable JSON parsing; falls back to
# grep -oP if jq is missing, so the logger still works either way.
#
# Known limitation: attribution of WHICH host user ran a docker command
# is best-effort, based on the most recent "docker ..." entry in
# activity.log. Commands issued directly against the Docker API/socket
# (bypassing the docker CLI) and `docker exec` processes started by the
# daemon itself are not tied to a real login session by the kernel, so
# they may show as "unknown".

LOG_DIR="/var/log/user_monitor"
DOCKER_LOG="$LOG_DIR/docker_activity.log"
MAX_SIZE=$((3*1024*1024))
ENABLE_COLOR_LOGS=true

if [[ "$ENABLE_COLOR_LOGS" == "true" ]]; then
    CLR_START='\033[0;32m'    # green   - start/create/unpause
    CLR_STOP='\033[0;33m'     # yellow  - stop/pause/restart
    CLR_DIE='\033[0;31m'      # red     - die/kill/destroy/remove
    CLR_OTHER='\033[0;35m'    # magenta - anything else (exec, etc.)
    CLR_RESET='\033[0m'
else
    CLR_START=''; CLR_STOP=''; CLR_DIE=''; CLR_OTHER=''; CLR_RESET=''
fi

HAVE_JQ=0
command -v jq >/dev/null 2>&1 && HAVE_JQ=1

mkdir -p "$LOG_DIR"

rotate() {
    if [[ -f "$DOCKER_LOG" ]]; then
        local size
        size=$(stat -c%s "$DOCKER_LOG" 2>/dev/null || echo 0)
        if (( size >= MAX_SIZE )); then
            mv "$DOCKER_LOG" "${DOCKER_LOG%.log}_$(date '+%Y%m%d_%H%M%S').log"
        fi
    fi
}

color_for_action() {
    case "$1" in
        start|create|unpause|connect|attach) echo -e "$CLR_START" ;;
        stop|pause|restart|disconnect)       echo -e "$CLR_STOP" ;;
        die|kill|destroy|remove|oom)         echo -e "$CLR_DIE" ;;
        *)                                   echo -e "$CLR_OTHER" ;;
    esac
}

docker events --format '{{json .}}' | while read -r line; do
    rotate

    if [[ "$HAVE_JQ" -eq 1 ]]; then
        etype=$(echo "$line"  | jq -r '.Type // "unknown"')
        action=$(echo "$line" | jq -r '.Action // "unknown"')
        cid=$(echo "$line"    | jq -r '.id // .Actor.ID // "unknown"' | cut -c1-12)
        cname=$(echo "$line"  | jq -r '.Actor.Attributes.name // empty')
    else
        etype=$(echo "$line"  | grep -oP '"Type":"\K[^"]+')
        action=$(echo "$line" | grep -oP '"Action":"\K[^"]+')
        cid=$(echo "$line"    | grep -oP '"id":"\K[^"]{1,12}')
        cname=$(echo "$line"  | grep -oP '"name":"\K[^"]+' | head -1)
    fi
    ts=$(date '+%Y-%m-%d %H:%M:%S')

    # Match against the new pretty-log format:  "... | user: NAME | cmd: docker ..."
    # (also matches the older standalone docker-compose binary)
    triggered_by=$(grep -E '\| cmd: docker(-compose)?( |$)' "$LOG_DIR/activity.log" 2>/dev/null | tail -1 | grep -oP 'user: \K[^ |]+')
    [[ -z "$triggered_by" ]] && triggered_by="unknown (non-CLI or API call)"

    clr=$(color_for_action "$action")

    {
    echo -e "${clr}+------------------------------------------+"
    echo -e "| DOCKER EVENT"
    echo -e "|   type      : $etype"
    echo -e "|   action    : $action"
    echo -e "|   container : ${cname:-$cid}"
    echo -e "|   id        : $cid"
    echo -e "|   by user   : $triggered_by"
    echo -e "|   time      : $ts"
    echo -e "+------------------------------------------+${CLR_RESET}"
    } >> "$DOCKER_LOG"
done
DOCKER_EOF
    chmod +x "$DOCKER_SCRIPT"
    ok "Docker logger installed at $DOCKER_SCRIPT"

    cat > "$DOCKER_SERVICE" << DOCKERSVC_EOF
[Unit]
Description=Docker Monitor - Human Readable Container Activity Log
After=docker.service
Requires=docker.service

[Service]
ExecStart=$DOCKER_SCRIPT
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
DOCKERSVC_EOF

    systemctl daemon-reload
    systemctl enable --now docker-monitor-pretty.service
    if systemctl is-active --quiet docker-monitor-pretty.service; then
        ok "docker-monitor-pretty.service is running."
    else
        err "docker-monitor-pretty.service failed to start. Check: journalctl -u docker-monitor-pretty.service"
    fi
    DOCKER_INSTALLED=1
else
    warn "Docker not found on this system. Skipping Docker monitor (safe to ignore if you don't use Docker)."
    DOCKER_INSTALLED=0
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
title "Setup complete."
echo "-----------------------------------------------------------"
echo "Commands + login/logout log : $LOG_DIR/activity.log   (real-time, event-driven)"
if [[ "$DOCKER_INSTALLED" -eq 1 ]]; then
echo "Docker/container activity   : $LOG_DIR/docker_activity.log"
fi
echo "Raw audit trail (legal copy): /var/log/audit/audit.log"
echo "Every log rotates at 3MB; old files are kept, never deleted."
echo "View colored logs with: cat <file> | less -R"
echo ""
title "==================== Gaps this closes ===================="
echo "- Clearing bash history or editing .bashrc no longer hides activity"
echo "- Commands run from any shell (zsh, fish, python -c, etc.) are logged"
echo "- Commands run after su/sudo stay tied to the original logged-in user"
echo "- Non-interactive processes (scripts, cron jobs) are logged too"
echo "- Container start/stop/exec/remove events are logged separately"
echo "- No more self-generated polling noise flooding the log (v3 fix)"
echo ""
title "==================== Remaining limitation ===================="
echo "A user with full root access can still stop auditd or the Docker"
echo "daemon, or delete local log files. No local script can fully prevent"
echo "that -- it's an inherent property of root access on Linux."
echo "The only real fix is forwarding logs in real time to an external"
echo "log server the users have no root access to (e.g. rsyslog or"
echo "audisp-remote). Ask if you'd like that set up as well."
echo ""
echo "To remove everything installed by this script, run:"
echo "  sudo bash $0 --uninstall"

#!/bin/bash

# ============================================
# Command Logger Script - FINAL COMPLETE VERSION
# By Mohamed Anwar
# 00201555201498
# mr.php0@gmail.com
# ============================================

# Configuration paths - Use a single directory for all users
# This ensures root can see all users' logs
LOG_BASE="/var/log/user_commands"
LOG_DIR="$LOG_BASE"
USER_LOG_DIR="$LOG_BASE/users"
MASTER_LOG="$LOG_BASE/master_commands.log"

# Create directories if they don't exist
sudo mkdir -p "$USER_LOG_DIR" 2>/dev/null
sudo touch "$MASTER_LOG" 2>/dev/null
sudo chmod 755 "$LOG_BASE" 2>/dev/null
sudo chmod 755 "$USER_LOG_DIR" 2>/dev/null
sudo chmod 666 "$MASTER_LOG" 2>/dev/null

# Get user information
USERNAME=$(whoami)
USER_LOG_FILE="$USER_LOG_DIR/${USERNAME}_commands.log"

# Create user log file with proper permissions
touch "$USER_LOG_FILE" 2>/dev/null
chmod 666 "$USER_LOG_FILE" 2>/dev/null

# ============================================
# Get Server IP Address
# ============================================

get_server_ip() {
    local server_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$server_ip" ]; then
        server_ip=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}' 2>/dev/null)
    fi
    if [ -z "$server_ip" ]; then
        server_ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    fi
    if [ -z "$server_ip" ]; then
        server_ip="Unknown"
    fi
    echo "$server_ip"
}

# ============================================
# Get User IP Address
# ============================================

get_user_ip() {
    local user_ip=$(who am i 2>/dev/null | awk '{print $NF}' | tr -d '()')
    if [ -z "$user_ip" ] || [ "$user_ip" = ":0" ] || [ "$user_ip" = ":0.0" ]; then
        user_ip=$(echo "$SSH_CONNECTION" | awk '{print $1}')
    fi
    if [ -z "$user_ip" ]; then
        user_ip=$(who -m 2>/dev/null | awk '{print $NF}' | tr -d '()')
    fi
    if [ -z "$user_ip" ] || [ "$user_ip" = ":0" ]; then
        user_ip="localhost"
    fi
    echo "$user_ip"
}

# ============================================
# Print Table Functions
# ============================================

print_table_header() {
    local title="$1"
    local width=${2:-90}
    printf "+%s+\n" "$(printf '%0.s-' $(seq 1 $((width-2))))"
    printf "| %-*s |\n" $((width-4)) "$title"
    printf "+%s+\n" "$(printf '%0.s-' $(seq 1 $((width-2))))"
}

print_table_footer() {
    local width=${1:-90}
    printf "+%s+\n" "$(printf '%0.s-' $(seq 1 $((width-2))))"
}

# ============================================
# Welcome Message Function
# ============================================

show_welcome() {
    local login_time=$(date '+%Y-%m-%d %H:%M:%S')
    local server_ip=$(get_server_ip)
    local user_ip=$(get_user_ip)
    local hostname=$(hostname)
    local session_id=$$
    local terminal=$(tty 2>/dev/null)
    local os_name=$(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || uname -s)
    
    [ -z "$terminal" ] && terminal="unknown"
    
    clear
    echo ""
    print_table_header "  WELCOME TO $(echo $hostname | tr '[:lower:]' '[:upper:]')  " 90
    
    # User Info
    printf "| %-25s | %-55s |\n" "Username" "$USERNAME"
    printf "| %-25s | %-55s |\n" "Hostname" "$hostname"
    printf "| %-25s | %-55s |\n" "Server IP" "$server_ip"
    printf "| %-25s | %-55s |\n" "Your IP" "$user_ip"
    printf "| %-25s | %-55s |\n" "Login Time" "$login_time"
    printf "| %-25s | %-55s |\n" "Terminal" "$terminal"
    printf "| %-25s | %-55s |\n" "Session ID" "$session_id"
    
    print_table_footer 90
    echo ""
    
    # System Info
    print_table_header "  SYSTEM INFORMATION  " 90
    printf "| %-25s | %-55s |\n" "OS" "$os_name"
    printf "| %-25s | %-55s |\n" "Kernel" "$(uname -r)"
    printf "| %-25s | %-55s |\n" "Uptime" "$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
    printf "| %-25s | %-55s |\n" "Load Average" "$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')"
    printf "| %-25s | %-55s |\n" "Memory Usage" "$(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    printf "| %-25s | %-55s |\n" "Disk Usage" "$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    print_table_footer 90
    echo ""
}

# ============================================
# Login Function
# ============================================

log_login() {
    local login_time=$(date '+%Y-%m-%d %H:%M:%S')
    local user_ip=$(get_user_ip)
    local server_ip=$(get_server_ip)
    local terminal=$(tty 2>/dev/null)
    local session_id=$$
    local hostname=$(hostname)
    
    [ -z "$terminal" ] && terminal="unknown"
    
    echo "[LOGIN] $USERNAME | $login_time | Host: $hostname | Server IP: $server_ip | User IP: $user_ip | Terminal: $terminal | Session: $session_id" >> "$MASTER_LOG"
    echo "[LOGIN] $login_time | Host: $hostname | Server IP: $server_ip | User IP: $user_ip | Terminal: $terminal | Session: $session_id" >> "$USER_LOG_FILE"
}

# ============================================
# Command Logging Function
# ============================================

log_command() {
    local command="$1"
    local command_time=$(date '+%Y-%m-%d %H:%M:%S')
    local pwd_path=$(pwd 2>/dev/null || echo "unknown")
    
    # Clean command
    command=$(echo "$command" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # Skip empty commands and internal commands
    if [ -z "$command" ] || [[ "$command" == "show_my_logs" ]] || [[ "$command" == "count_my_commands" ]] || [[ "$command" == "show_user_logs" ]] || [[ "$command" == "debug_show_raw" ]]; then
        return
    fi
    
    # Skip welcome and login commands
    if [[ "$command" == "clear" ]] || [[ "$command" == "reset" ]]; then
        return
    fi
    
    # Escape special characters
    command=$(echo "$command" | sed 's/|/\\|/g')
    
    echo "[CMD] $command_time | $pwd_path | $command" >> "$MASTER_LOG"
    echo "[CMD] $command_time | $pwd_path | $command" >> "$USER_LOG_FILE"
}

# ============================================
# Logout Function
# ============================================

log_logout() {
    local logout_time=$(date '+%Y-%m-%d %H:%M:%S')
    local session_id=$$
    
    echo "[LOGOUT] $USERNAME | $logout_time | Session: $session_id" >> "$MASTER_LOG"
    echo "[LOGOUT] $logout_time | Session: $session_id" >> "$USER_LOG_FILE"
}

# ============================================
# Show User Logs Function - For normal users
# ============================================

show_my_logs() {
    local log_file="$USER_LOG_FILE"
    
    if [ ! -f "$log_file" ]; then
        echo "❌ No logs found for user: $USERNAME"
        return 1
    fi
    
    # Check if there are any commands
    local total_cmds=$(grep -c "^\[CMD\]" "$log_file" 2>/dev/null)
    if [ "$total_cmds" -eq 0 ]; then
        echo ""
        print_table_header " COMMAND HISTORY FOR $USERNAME " 90
        printf "| %-80s |\n" "No commands found"
        print_table_footer 90
        echo ""
        return 0
    fi
    
    echo ""
    print_table_header " COMMAND HISTORY FOR $USERNAME " 110
    
    # Table header
    printf "| %-5s | %-22s | %-35s | %-40s |\n" "#" "Date & Time" "Directory" "Command"
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 7))" \
        "$(printf '%0.s-' $(seq 1 24))" \
        "$(printf '%0.s-' $(seq 1 37))" \
        "$(printf '%0.s-' $(seq 1 42))"
    
    local counter=1
    
    # Read the log file and extract data
    grep "^\[CMD\]" "$log_file" | tail -50 | while read -r line; do
        local rest="${line#*] }"
        local cmd_time=$(echo "$rest" | cut -d'|' -f1 | sed 's/^[ \t]*//;s/[ \t]*$//')
        local cmd_path=$(echo "$rest" | cut -d'|' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')
        local cmd_text=$(echo "$rest" | cut -d'|' -f3- | sed 's/^[ \t]*//;s/[ \t]*$//')
        
        if [ -z "$cmd_text" ] || [ "$cmd_text" = "" ]; then
            continue
        fi
        
        if [ ${#cmd_text} -gt 38 ]; then
            cmd_text="${cmd_text:0:35}..."
        fi
        if [ ${#cmd_path} -gt 33 ]; then
            cmd_path="...${cmd_path: -30}"
        fi
        if [ ${#cmd_time} -gt 20 ]; then
            cmd_time="${cmd_time:0:20}"
        fi
        
        printf "| %-5d | %-22s | %-35s | %-40s |\n" "$counter" "$cmd_time" "$cmd_path" "$cmd_text"
        counter=$((counter + 1))
    done
    
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 7))" \
        "$(printf '%0.s-' $(seq 1 24))" \
        "$(printf '%0.s-' $(seq 1 37))" \
        "$(printf '%0.s-' $(seq 1 42))"
    echo ""
    
    local total_all_cmds=$(grep -c "^\[CMD\]" "$log_file" 2>/dev/null || echo "0")
    local total_logins=$(grep -c "^\[LOGIN\]" "$log_file" 2>/dev/null || echo "0")
    local total_logouts=$(grep -c "^\[LOGOUT\]" "$log_file" 2>/dev/null || echo "0")
    
    print_table_header " STATISTICS " 80
    printf "| %-35s | %-35s |\n" "Total Commands" "$total_all_cmds"
    printf "| %-35s | %-35s |\n" "Total Logins" "$total_logins"
    printf "| %-35s | %-35s |\n" "Total Logouts" "$total_logouts"
    print_table_footer 80
    echo ""
}

# ============================================
# Show All Users Logs - ROOT ONLY
# ============================================

show_user_logs() {
    # Check if user is root
    if [ "$USERNAME" != "root" ]; then
        echo "❌ Access denied. Only root can view other users' logs."
        return 1
    fi
    
    # If no argument, show all users
    if [ -z "$1" ]; then
        echo ""
        print_table_header " ALL USERS COMMAND HISTORY " 110
        
        # List all user log files
        for user_log in "$USER_LOG_DIR"/*_commands.log; do
            if [ -f "$user_log" ]; then
                local username=$(basename "$user_log" | sed 's/_commands.log//')
                local total_cmds=$(grep -c "^\[CMD\]" "$user_log" 2>/dev/null || echo "0")
                
                if [ "$total_cmds" -gt 0 ]; then
                    echo ""
                    print_table_header " USER: $username (Last 10 commands) " 110
                    
                    printf "| %-5s | %-22s | %-35s | %-40s |\n" "#" "Date & Time" "Directory" "Command"
                    printf "+%s+%s+%s+%s+\n" \
                        "$(printf '%0.s-' $(seq 1 7))" \
                        "$(printf '%0.s-' $(seq 1 24))" \
                        "$(printf '%0.s-' $(seq 1 37))" \
                        "$(printf '%0.s-' $(seq 1 42))"
                    
                    local counter=1
                    grep "^\[CMD\]" "$user_log" | tail -10 | while read -r line; do
                        local rest="${line#*] }"
                        local cmd_time=$(echo "$rest" | cut -d'|' -f1 | sed 's/^[ \t]*//;s/[ \t]*$//')
                        local cmd_path=$(echo "$rest" | cut -d'|' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')
                        local cmd_text=$(echo "$rest" | cut -d'|' -f3- | sed 's/^[ \t]*//;s/[ \t]*$//')
                        
                        if [ -z "$cmd_text" ] || [ "$cmd_text" = "" ]; then
                            continue
                        fi
                        
                        if [ ${#cmd_text} -gt 38 ]; then
                            cmd_text="${cmd_text:0:35}..."
                        fi
                        if [ ${#cmd_path} -gt 33 ]; then
                            cmd_path="...${cmd_path: -30}"
                        fi
                        if [ ${#cmd_time} -gt 20 ]; then
                            cmd_time="${cmd_time:0:20}"
                        fi
                        
                        printf "| %-5d | %-22s | %-35s | %-40s |\n" "$counter" "$cmd_time" "$cmd_path" "$cmd_text"
                        counter=$((counter + 1))
                    done
                    
                    printf "+%s+%s+%s+%s+\n" \
                        "$(printf '%0.s-' $(seq 1 7))" \
                        "$(printf '%0.s-' $(seq 1 24))" \
                        "$(printf '%0.s-' $(seq 1 37))" \
                        "$(printf '%0.s-' $(seq 1 42))"
                    
                    echo "📊 Total commands for $username: $total_cmds"
                fi
            fi
        done
        
        echo ""
        return 0
    fi
    
    # Show specific user's logs
    local target_user="$1"
    local target_log="$USER_LOG_DIR/${target_user}_commands.log"
    
    if [ ! -f "$target_log" ]; then
        echo "❌ No logs found for user: $target_user"
        echo ""
        echo "📋 Available users:"
        ls -la "$USER_LOG_DIR" 2>/dev/null | grep "_commands.log" | sed 's/.*_commands.log//' | sed 's/.*\///' | while read line; do
            echo "  - $line"
        done
        return 1
    fi
    
    local total_cmds=$(grep -c "^\[CMD\]" "$target_log" 2>/dev/null)
    if [ "$total_cmds" -eq 0 ]; then
        echo ""
        print_table_header " COMMAND HISTORY FOR $target_user " 90
        printf "| %-80s |\n" "No commands found"
        print_table_footer 90
        echo ""
        return 0
    fi
    
    echo ""
    print_table_header " COMMAND HISTORY FOR $target_user " 110
    
    printf "| %-5s | %-22s | %-35s | %-40s |\n" "#" "Date & Time" "Directory" "Command"
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 7))" \
        "$(printf '%0.s-' $(seq 1 24))" \
        "$(printf '%0.s-' $(seq 1 37))" \
        "$(printf '%0.s-' $(seq 1 42))"
    
    local counter=1
    grep "^\[CMD\]" "$target_log" | tail -50 | while read -r line; do
        local rest="${line#*] }"
        local cmd_time=$(echo "$rest" | cut -d'|' -f1 | sed 's/^[ \t]*//;s/[ \t]*$//')
        local cmd_path=$(echo "$rest" | cut -d'|' -f2 | sed 's/^[ \t]*//;s/[ \t]*$//')
        local cmd_text=$(echo "$rest" | cut -d'|' -f3- | sed 's/^[ \t]*//;s/[ \t]*$//')
        
        if [ -z "$cmd_text" ] || [ "$cmd_text" = "" ]; then
            continue
        fi
        
        if [ ${#cmd_text} -gt 38 ]; then
            cmd_text="${cmd_text:0:35}..."
        fi
        if [ ${#cmd_path} -gt 33 ]; then
            cmd_path="...${cmd_path: -30}"
        fi
        if [ ${#cmd_time} -gt 20 ]; then
            cmd_time="${cmd_time:0:20}"
        fi
        
        printf "| %-5d | %-22s | %-35s | %-40s |\n" "$counter" "$cmd_time" "$cmd_path" "$cmd_text"
        counter=$((counter + 1))
    done
    
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 7))" \
        "$(printf '%0.s-' $(seq 1 24))" \
        "$(printf '%0.s-' $(seq 1 37))" \
        "$(printf '%0.s-' $(seq 1 42))"
    echo ""
    
    local total_all_cmds=$(grep -c "^\[CMD\]" "$target_log" 2>/dev/null || echo "0")
    local total_logins=$(grep -c "^\[LOGIN\]" "$target_log" 2>/dev/null || echo "0")
    local total_logouts=$(grep -c "^\[LOGOUT\]" "$target_log" 2>/dev/null || echo "0")
    
    print_table_header " STATISTICS FOR $target_user " 80
    printf "| %-35s | %-35s |\n" "Total Commands" "$total_all_cmds"
    printf "| %-35s | %-35s |\n" "Total Logins" "$total_logins"
    printf "| %-35s | %-35s |\n" "Total Logouts" "$total_logouts"
    print_table_footer 80
    echo ""
}

# ============================================
# Debug Function
# ============================================

debug_show_raw() {
    echo "=== RAW LOG CONTENT (last 10 lines) ==="
    cat "$USER_LOG_FILE" | tail -10
    echo ""
    echo "=== COMMAND ENTRIES (last 5) ==="
    grep "^\[CMD\]" "$USER_LOG_FILE" | tail -5
    echo ""
    echo "=== TOTAL COMMANDS: $(grep -c '^\[CMD\]' "$USER_LOG_FILE" 2>/dev/null || echo 0)"
    echo ""
    echo "=== LOG DIRECTORY CONTENTS ==="
    ls -la "$USER_LOG_DIR" 2>/dev/null || echo "No users directory"
}

# ============================================
# Count Commands Function
# ============================================

count_my_commands() {
    if [ -f "$USER_LOG_FILE" ]; then
        local count=$(grep -c "^\[CMD\]" "$USER_LOG_FILE" 2>/dev/null || echo "0")
        echo "📊 Total commands executed: $count"
    else
        echo "📊 Total commands: 0"
    fi
}

# ============================================
# Export Functions
# ============================================

export -f show_my_logs count_my_commands debug_show_raw show_user_logs

# ============================================
# Main Execution
# ============================================

# Show welcome message (only for interactive shells)
if [ -t 0 ] && [ -n "$PS1" ]; then
    show_welcome
fi

# Log login
log_login

# Enable command logging via DEBUG trap
trap 'last_command=$(history 1 2>/dev/null | sed "s/^[ ]*[0-9]*[ ]*//"); log_command "$last_command"' DEBUG

# Log logout on exit
trap log_logout EXIT

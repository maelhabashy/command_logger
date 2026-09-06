#!/bin/bash

# ============================================
# User Activity Monitor - Complete Version
# ============================================

# Configuration
LOG_DIR="$HOME/.command_logs"
MASTER_LOG="$LOG_DIR/master_commands.log"
USER_LOG_DIR="$LOG_DIR/users"

# ============================================
# Table Printing Functions
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
# Function: Show Active Users
# ============================================

show_active_users() {
    clear
    echo ""
    print_table_header " ACTIVE USERS " 90
    printf "| %-20s | %-25s | %-20s | %-15s |\n" "Username" "Login Time" "Terminal" "IP Address"
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 22))" \
        "$(printf '%0.s-' $(seq 1 27))" \
        "$(printf '%0.s-' $(seq 1 22))" \
        "$(printf '%0.s-' $(seq 1 17))"
    
    who 2>/dev/null | while read line; do
        username=$(echo "$line" | awk '{print $1}')
        terminal=$(echo "$line" | awk '{print $2}')
        login_time=$(echo "$line" | awk '{print $3, $4}')
        ip=$(echo "$line" | awk '{print $NF}' | tr -d '()')
        [ -z "$ip" ] && ip="localhost"
        
        printf "| %-20s | %-25s | %-20s | %-15s |\n" "$username" "$login_time" "$terminal" "$ip"
    done
    
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 22))" \
        "$(printf '%0.s-' $(seq 1 27))" \
        "$(printf '%0.s-' $(seq 1 22))" \
        "$(printf '%0.s-' $(seq 1 17))"
    echo ""
}

# ============================================
# Function: Show Recent Commands
# ============================================

show_recent_commands() {
    clear
    echo ""
    
    if [ ! -f "$MASTER_LOG" ]; then
        print_table_header " ERROR " 80
        printf "| %-70s |\n" "❌ No logs found"
        print_table_footer 80
        echo ""
        return 1
    fi
    
    print_table_header " RECENT COMMANDS (LAST 20) " 90
    printf "| %-15s | %-22s | %-35s |\n" "User" "Date & Time" "Command"
    printf "+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 17))" \
        "$(printf '%0.s-' $(seq 1 24))" \
        "$(printf '%0.s-' $(seq 1 37))"
    
    tail -n 20 "$MASTER_LOG" 2>/dev/null | grep "^\[CMD\]" | while IFS= read -r line; do
        local user=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' | sed 's/^\[CMD\] //')
        local cmd_time=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        local cmd_text=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
        
        if [ -z "$cmd_text" ]; then
            cmd_text=$(echo "$line" | cut -d'|' -f4- | sed 's/^[ \t]*//;s/[ \t]*$//')
        fi
        
        if [ ${#cmd_text} -gt 33 ]; then
            cmd_text="${cmd_text:0:30}..."
        fi
        
        printf "| %-15s | %-22s | %-35s |\n" "$user" "$cmd_time" "$cmd_text"
    done
    
    printf "+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 17))" \
        "$(printf '%0.s-' $(seq 1 24))" \
        "$(printf '%0.s-' $(seq 1 37))"
    echo ""
}

# ============================================
# Function: Show User Statistics
# ============================================

show_user_stats() {
    clear
    echo ""
    
    if [ ! -d "$USER_LOG_DIR" ]; then
        print_table_header " ERROR " 80
        printf "| %-70s |\n" "❌ No logs found"
        print_table_footer 80
        echo ""
        return 1
    fi
    
    print_table_header " USER STATISTICS " 90
    printf "| %-20s | %-15s | %-15s | %-15s |\n" "Username" "Commands" "Logins" "Logouts"
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 22))" \
        "$(printf '%0.s-' $(seq 1 17))" \
        "$(printf '%0.s-' $(seq 1 17))" \
        "$(printf '%0.s-' $(seq 1 17))"
    
    for user_log in "$USER_LOG_DIR"/*_commands.log; do
        if [ -f "$user_log" ]; then
            username=$(basename "$user_log" | sed 's/_commands.log//')
            cmd_count=$(grep -c "^\[CMD\]" "$user_log" 2>/dev/null || echo "0")
            login_count=$(grep -c "^\[LOGIN\]" "$user_log" 2>/dev/null || echo "0")
            logout_count=$(grep -c "^\[LOGOUT\]" "$user_log" 2>/dev/null || echo "0")
            
            printf "| %-20s | %-15s | %-15s | %-15s |\n" \
                "$username" "$cmd_count" "$login_count" "$logout_count"
        fi
    done
    
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 22))" \
        "$(printf '%0.s-' $(seq 1 17))" \
        "$(printf '%0.s-' $(seq 1 17))" \
        "$(printf '%0.s-' $(seq 1 17))"
    echo ""
}

# ============================================
# Function: Show Specific User Log
# ============================================

show_user_log() {
    local username="$1"
    local user_log="$USER_LOG_DIR/${username}_commands.log"
    
    clear
    echo ""
    
    if [ ! -f "$user_log" ]; then
        print_table_header " ERROR " 80
        printf "| %-70s |\n" "❌ No logs found for user: $username"
        print_table_footer 80
        echo ""
        return 1
    fi
    
    print_table_header " COMMAND HISTORY: $username " 90
    printf "| %-4s | %-20s | %-35s |\n" "#" "Date & Time" "Command"
    printf "+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 6))" \
        "$(printf '%0.s-' $(seq 1 22))" \
        "$(printf '%0.s-' $(seq 1 37))"
    
    local counter=1
    grep "^\[CMD\]" "$user_log" | tail -30 | while IFS= read -r line; do
        local cmd_time=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
        local cmd_text=$(echo "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
        
        if [ -z "$cmd_text" ]; then
            cmd_text=$(echo "$line" | cut -d'|' -f4- | sed 's/^[ \t]*//;s/[ \t]*$//')
        fi
        
        if [ ${#cmd_text} -gt 33 ]; then
            cmd_text="${cmd_text:0:30}..."
        fi
        
        printf "| %-4d | %-20s | %-35s |\n" "$counter" "$cmd_time" "$cmd_text"
        counter=$((counter + 1))
    done
    
    printf "+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 6))" \
        "$(printf '%0.s-' $(seq 1 22))" \
        "$(printf '%0.s-' $(seq 1 37))"
    echo ""
    
    # Summary
    local total_cmds=$(grep -c "^\[CMD\]" "$user_log" 2>/dev/null || echo "0")
    local total_logins=$(grep -c "^\[LOGIN\]" "$user_log" 2>/dev/null || echo "0")
    local total_logouts=$(grep -c "^\[LOGOUT\]" "$user_log" 2>/dev/null || echo "0")
    
    print_table_header " SUMMARY: $username " 80
    printf "| %-30s | %-40s |\n" "Total Commands" "$total_cmds"
    printf "| %-30s | %-40s |\n" "Total Logins" "$total_logins"
    printf "| %-30s | %-40s |\n" "Total Logouts" "$total_logouts"
    print_table_footer 80
    echo ""
}

# ============================================
# Function: Clean Old Logs
# ============================================

clean_old_logs() {
    echo ""
    print_table_header " CLEANING OLD LOGS " 80
    printf "| %-70s |\n" "🧹 Removing logs older than 30 days..."
    
    if [ -d "$LOG_DIR" ]; then
        local deleted=$(find "$LOG_DIR" -name "*.log" -type f -mtime +30 -delete -print 2>/dev/null | wc -l)
        printf "| %-70s |\n" "✅ Deleted $deleted log files"
    else
        printf "| %-70s |\n" "❌ No log directory found"
    fi
    
    print_table_footer 80
    echo ""
}

# ============================================
# Function: Show Full Log
# ============================================

show_full_log() {
    clear
    echo ""
    
    if [ ! -f "$MASTER_LOG" ]; then
        print_table_header " ERROR " 80
        printf "| %-70s |\n" "❌ No master log found"
        print_table_footer 80
        echo ""
        return 1
    fi
    
    print_table_header " FULL COMMAND LOG (LAST 30) " 90
    printf "| %-15s | %-22s | %-10s | %-35s |\n" "User" "Date & Time" "Type" "Details"
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 17))" \
        "$(printf '%0.s-' $(seq 1 24))" \
        "$(printf '%0.s-' $(seq 1 12))" \
        "$(printf '%0.s-' $(seq 1 37))"
    
    tail -n 30 "$MASTER_LOG" 2>/dev/null | while IFS= read -r line; do
        local type=$(echo "$line" | cut -d']' -f1 | sed 's/^\[//')
        local rest=$(echo "$line" | cut -d']' -f2- | sed 's/^ //')
        
        if [ "$type" = "CMD" ]; then
            local user=$(echo "$rest" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')
            local cmd_time=$(echo "$rest" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            local details=$(echo "$rest" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $4); print $4}')
            
            if [ -z "$details" ]; then
                details=$(echo "$rest" | cut -d'|' -f4- | sed 's/^[ \t]*//;s/[ \t]*$//')
            fi
            
            if [ ${#details} -gt 33 ]; then
                details="${details:0:30}..."
            fi
            
            printf "| %-15s | %-22s | %-10s | %-35s |\n" "$user" "$cmd_time" "$type" "$details"
        else
            local user=$(echo "$rest" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}')
            local log_time=$(echo "$rest" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')
            local details=$(echo "$rest" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
            
            if [ ${#details} -gt 33 ]; then
                details="${details:0:30}..."
            fi
            
            printf "| %-15s | %-22s | %-10s | %-35s |\n" "$user" "$log_time" "$type" "$details"
        fi
    done
    
    printf "+%s+%s+%s+%s+\n" \
        "$(printf '%0.s-' $(seq 1 17))" \
        "$(printf '%0.s-' $(seq 1 24))" \
        "$(printf '%0.s-' $(seq 1 12))" \
        "$(printf '%0.s-' $(seq 1 37))"
    echo ""
}

# ============================================
# Uninstall Function
# ============================================

uninstall_logger() {
    echo ""
    print_table_header " UNINSTALL COMMAND LOGGER " 80
    printf "| %-70s |\n" "⚠️  This will remove all logger files and data"
    printf "| %-70s |\n" ""
    printf "| %-70s |\n" "📁 Files to be removed:"
    printf "| %-70s |\n" "  - /usr/m1/command_logger.sh"
    printf "| %-70s |\n" "  - /usr/m1/monitor.sh"
    printf "| %-70s |\n" "  - /etc/profile.d/user_command_logger.sh"
    printf "| %-70s |\n" "  - ~/.command_logs/ (all logs)"
    print_table_footer 80
    echo ""
    
    echo -n "Are you sure you want to uninstall? (y/N): "
    read confirm
    
    if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
        echo "❌ Uninstall cancelled"
        return 1
    fi
    
    echo ""
    printf "| %-70s |\n" "🗑️  Removing scripts..."
    
    # Remove scripts
    sudo rm -f /usr/m1/command_logger.sh
    sudo rm -f /usr/m1/monitor.sh
    sudo rm -f /etc/profile.d/user_command_logger.sh
    
    printf "| %-70s |\n" "🗑️  Removing log files..."
    
    # Remove logs
    echo -n "Remove all log files? (y/N): "
    read remove_logs
    
    if [[ "$remove_logs" == "y" ]] || [[ "$remove_logs" == "Y" ]]; then
        rm -rf "$HOME/.command_logs"
        printf "| %-70s |\n" "✅ Logs removed"
    else
        printf "| %-70s |\n" "📁 Logs kept at: $HOME/.command_logs"
    fi
    
    # Remove cron job
    printf "| %-70s |\n" "🗑️  Removing cron jobs..."
    crontab -l 2>/dev/null | grep -v "monitor.sh" | crontab -
    
    print_table_header " UNINSTALL COMPLETE " 80
    printf "| %-70s |\n" "✅ Command logger has been uninstalled"
    printf "| %-70s |\n" "📌 Please restart your shell or logout/login"
    print_table_footer 80
    echo ""
}

# ============================================
# Main Menu
# ============================================

show_menu() {
    clear
    echo ""
    print_table_header " USER ACTIVITY MONITOR " 80
    printf "| %-70s |\n" "1. Show Active Users"
    printf "| %-70s |\n" "2. Show Recent Commands (Last 20)"
    printf "| %-70s |\n" "3. Show User Statistics"
    printf "| %-70s |\n" "4. Show Specific User Log"
    printf "| %-70s |\n" "5. Clean Old Logs (30+ days)"
    printf "| %-70s |\n" "6. Show Full Log (Last 30 entries)"
    printf "| %-70s |\n" "7. Uninstall Logger"
    printf "| %-70s |\n" "0. Exit"
    print_table_footer 80
    echo ""
    echo -n "Select option: "
}

# ============================================
# Main Loop
# ============================================

while true; do
    show_menu
    read choice
    
    case $choice in
        1) show_active_users ;;
        2) show_recent_commands ;;
        3) show_user_stats ;;
        4) 
            echo ""
            echo -n "Enter username: "
            read username
            show_user_log "$username"
            ;;
        5) clean_old_logs ;;
        6) show_full_log ;;
        7) uninstall_logger
           if [ $? -eq 0 ]; then
               echo "Please restart your shell or logout/login"
               break
           fi
           ;;
        0) 
            echo ""
            print_table_header " GOODBYE " 80
            printf "| %-70s |\n" "👋 Exiting monitor"
            print_table_footer 80
            echo ""
            break
            ;;
        *) 
            echo ""
            print_table_header " ERROR " 80
            printf "| %-70s |\n" "❌ Invalid option"
            print_table_footer 80
            echo ""
            ;;
    esac
    
    if [ "$choice" != "0" ] && [ "$choice" != "7" ]; then
        echo ""
        echo -n "Press Enter to continue..."
        read
    fi
done

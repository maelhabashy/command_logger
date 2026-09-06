#!/bin/bash

# ============================================
# Uninstall Script - Command Logger Removal
# ============================================

print_table_header() {
    local title="$1"
    local width=${2:-80}
    printf "+%s+\n" "$(printf '%0.s-' $(seq 1 $((width-2))))"
    printf "| %-*s |\n" $((width-4)) "$title"
    printf "+%s+\n" "$(printf '%0.s-' $(seq 1 $((width-2))))"
}

print_table_footer() {
    local width=${1:-80}
    printf "+%s+\n" "$(printf '%0.s-' $(seq 1 $((width-2))))"
}

echo ""
print_table_header " UNINSTALL COMMAND LOGGER " 80

printf "| %-70s |\n" "⚠️  This will remove:"
printf "| %-70s |\n" ""
printf "| %-70s |\n" "📁 Scripts:"
printf "| %-70s |\n" "  - /usr/local/bin/command_logger.sh"
printf "| %-70s |\n" "  - /usr/local/bin/monitor.sh"
printf "| %-70s |\n" "  - /etc/profile.d/user_command_logger.sh"
printf "| %-70s |\n" ""
printf "| %-70s |\n" "📁 Log files:"
printf "| %-70s |\n" "  - $HOME/.command_logs/ (all logs)"
printf "| %-70s |\n" ""
printf "| %-70s |\n" "⏰ Cron jobs related to logger"
print_table_footer 80
echo ""

echo -n "Are you sure you want to uninstall? (y/N): "
read confirm

if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
    echo "❌ Uninstall cancelled"
    exit 0
fi

echo ""
print_table_header " REMOVING FILES... " 80

# Remove scripts
printf "| %-70s |\n" "🗑️  Removing scripts..."
sudo rm -f /usr/local/bin/command_logger.sh
sudo rm -f /usr/local/bin/monitor.sh
sudo rm -f /etc/profile.d/user_command_logger.sh

# Remove backup files
printf "| %-70s |\n" "🗑️  Removing backup files..."
sudo rm -f /usr/local/bin/command_logger.sh.bak*
sudo rm -f /usr/local/bin/monitor.sh.bak*
sudo rm -f /etc/profile.d/user_command_logger.sh.bak*

# Remove logs
echo -n "Remove all log files? (y/N): "
read remove_logs

if [[ "$remove_logs" == "y" ]] || [[ "$remove_logs" == "Y" ]]; then
    printf "| %-70s |\n" "🗑️  Removing log files..."
    rm -rf "$HOME/.command_logs"
    printf "| %-70s |\n" "✅ Logs removed"
else
    printf "| %-70s |\n" "📁 Logs kept at: $HOME/.command_logs"
fi

# Remove cron jobs
printf "| %-70s |\n" "🗑️  Removing cron jobs..."
crontab -l 2>/dev/null | grep -v "monitor.sh" | crontab -

print_table_footer 80
echo ""

print_table_header " UNINSTALL COMPLETE ✅ " 80
printf "| %-70s |\n" "✅ Command logger has been uninstalled"
printf "| %-70s |\n" ""
printf "| %-70s |\n" "📌 To complete removal:"
printf "| %-70s |\n" "  - Close and reopen your terminal"
printf "| %-70s |\n" "  - OR start a new shell session"
print_table_footer 80
echo ""

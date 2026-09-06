#!/bin/bash

# ============================================
# Installation Script - Complete Version
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

# ============================================
# Start Installation
# ============================================

echo ""
print_table_header " COMMAND LOGGER INSTALLATION " 80

if [ "$EUID" -eq 0 ]; then
    printf "| %-70s |\n" "⚠️  Running as root - installing system-wide"
else
    printf "| %-70s |\n" "✅ Running as user - installing in home directory"
fi
print_table_footer 80
echo ""

# ============================================
# Check for existing installation
# ============================================

EXISTING_INSTALL=0
[ -f /usr/local/bin/command_logger.sh ] && EXISTING_INSTALL=1
[ -f /usr/local/bin/monitor.sh ] && EXISTING_INSTALL=1
[ -f /etc/profile.d/user_command_logger.sh ] && EXISTING_INSTALL=1
[ -d "$HOME/.command_logs" ] && EXISTING_INSTALL=1

if [ $EXISTING_INSTALL -eq 1 ]; then
    print_table_header " WARNING " 80
    printf "| %-70s |\n" "⚠️  Existing installation detected"
    printf "| %-70s |\n" ""
    printf "| %-70s |\n" "Do you want to:"
    printf "| %-70s |\n" "  1. Overwrite (backup old files)"
    printf "| %-70s |\n" "  2. Uninstall first"
    printf "| %-70s |\n" "  3. Cancel installation"
    print_table_footer 80
    echo ""
    echo -n "Select option (1-3): "
    read choice
    
    case $choice in
        1)
            echo ""
            echo "📋 Backing up old files..."
            [ -f /usr/local/bin/command_logger.sh ] && sudo cp /usr/local/bin/command_logger.sh /usr/local/bin/command_logger.sh.bak.$(date +%s)
            [ -f /usr/local/bin/monitor.sh ] && sudo cp /usr/local/bin/monitor.sh /usr/local/bin/monitor.sh.bak.$(date +%s)
            [ -f /etc/profile.d/user_command_logger.sh ] && sudo cp /etc/profile.d/user_command_logger.sh /etc/profile.d/user_command_logger.sh.bak.$(date +%s)
            printf "| %-70s |\n" "✅ Backup completed"
            ;;
        2)
            echo ""
            echo "🗑️  Running uninstall..."
            if [ -f "./uninstall.sh" ]; then
                ./uninstall.sh
            elif [ -f /usr/local/bin/monitor.sh ]; then
                echo "5" | sudo /usr/local/bin/monitor.sh 2>/dev/null
            else
                sudo rm -f /usr/local/bin/command_logger.sh
                sudo rm -f /usr/local/bin/monitor.sh
                sudo rm -f /etc/profile.d/user_command_logger.sh
                rm -rf "$HOME/.command_logs"
                crontab -l 2>/dev/null | grep -v "monitor.sh" | crontab -
                echo "✅ Manual uninstall completed"
            fi
            ;;
        3)
            echo "❌ Installation cancelled"
            exit 0
            ;;
        *)
            echo "❌ Invalid option"
            exit 1
            ;;
    esac
fi

# ============================================
# Verify required files exist
# ============================================

echo ""
printf "| %-70s |\n" "📁 Checking required files..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$SCRIPT_DIR/command_logger.sh" ]; then
    printf "| %-70s |\n" "❌ command_logger.sh not found in: $SCRIPT_DIR"
    printf "| %-70s |\n" "Please ensure all files are in the same directory"
    print_table_footer 80
    exit 1
fi

if [ ! -f "$SCRIPT_DIR/monitor.sh" ]; then
    printf "| %-70s |\n" "❌ monitor.sh not found in: $SCRIPT_DIR"
    printf "| %-70s |\n" "Please ensure all files are in the same directory"
    print_table_footer 80
    exit 1
fi

printf "| %-70s |\n" "✅ All required files found"

# ============================================
# Create directories
# ============================================

printf "| %-70s |\n" "📁 Creating directories..."
mkdir -p "$HOME/.command_logs/users"
chmod 755 "$HOME/.command_logs"
chmod 755 "$HOME/.command_logs/users"

# ============================================
# Install command_logger.sh
# ============================================

printf "| %-70s |\n" "📝 Installing command logger..."
sudo cp "$SCRIPT_DIR/command_logger.sh" /usr/local/bin/
sudo chmod 755 /usr/local/bin/command_logger.sh

# ============================================
# Install monitor.sh
# ============================================

printf "| %-70s |\n" "📝 Installing monitor script..."
sudo cp "$SCRIPT_DIR/monitor.sh" /usr/local/bin/
sudo chmod 755 /usr/local/bin/monitor.sh

# ============================================
# Install profile script
# ============================================

printf "| %-70s |\n" "📝 Installing profile script..."

sudo bash -c 'cat > /etc/profile.d/user_command_logger.sh << "EOF"
#!/bin/bash

# ============================================
# User Command Logger - Profile Integration (Silent)
# ============================================

if [ -f /usr/local/bin/command_logger.sh ]; then
    source /usr/local/bin/command_logger.sh
else
    echo "⚠️  Command logger not found at /usr/local/bin/command_logger.sh"
fi

export -f show_my_logs count_my_commands
EOF'

sudo chmod 644 /etc/profile.d/user_command_logger.sh

# ============================================
# Add cron job for automatic cleanup
# ============================================

printf "| %-70s |\n" "⏰ Setting up automatic cleanup (daily at 2 AM)..."

crontab -l 2>/dev/null | grep -v "monitor.sh" | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/monitor.sh <<< \"5\" > /dev/null 2>&1") | crontab -

# ============================================
# Create default log files
# ============================================

printf "| %-70s |\n" "📁 Creating initial log files..."
touch "$HOME/.command_logs/master_commands.log"
chmod 644 "$HOME/.command_logs/master_commands.log"

# ============================================
# Installation Complete
# ============================================

print_table_header " INSTALLATION COMPLETE ✅ " 80
printf "| %-70s |\n" ""
printf "| %-70s |\n" "📌 Installed components:"
printf "| %-70s |\n" "  ✅ command_logger.sh -> /usr/local/bin/"
printf "| %-70s |\n" "  ✅ monitor.sh -> /usr/local/bin/"
printf "| %-70s |\n" "  ✅ profile script -> /etc/profile.d/"
printf "| %-70s |\n" "  ✅ cron job for cleanup"
printf "| %-70s |\n" "  ✅ log directory -> $HOME/.command_logs/"
printf "| %-70s |\n" ""
printf "| %-70s |\n" "📌 Commands available:"
printf "| %-70s |\n" "  show_my_logs      - View your command history"
printf "| %-70s |\n" "  count_my_commands - Count your commands"
printf "| %-70s |\n" "  monitor.sh        - Admin monitoring tool"
printf "| %-70s |\n" ""
printf "| %-70s |\n" "📌 To apply changes in current session:"
printf "| %-70s |\n" "  source /usr/local/bin/command_logger.sh"
printf "| %-70s |\n" "  OR logout and login again"
print_table_footer 80
echo ""

# ============================================
# Source the profile to enable in current session
# ============================================

echo -n "Do you want to enable the logger in this session? (Y/n): "
read enable_now

if [[ "$enable_now" != "n" ]] && [[ "$enable_now" != "N" ]]; then
    echo ""
    echo "🔄 Enabling logger in current session..."
    source /usr/local/bin/command_logger.sh 2>/dev/null
    echo "✅ Logger enabled!"
fi

echo ""
print_table_header " INSTALLATION COMPLETE " 80
printf "| %-70s |\n" "🎉 Command logger is now installed and working!"
printf "| %-70s |\n" "📊 Run: show_my_logs to see your command history"
print_table_footer 80
echo ""

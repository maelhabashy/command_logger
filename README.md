Command Logger System - Complete Documentation
📋 Table of Contents

    Overview

    Architecture

    Installation

    Configuration

    Commands Reference

    Log Files Structure

    User Guide

    Administrator Guide

    Troubleshooting

    Uninstallation

    Security

    FAQ

Overview
What is Command Logger?

The Command Logger is a comprehensive Bash-based system that tracks and records all user commands executed on a Linux server. It provides:

    Real-time command logging for all users

    User-specific history with timestamps

    Admin monitoring capabilities

    Login/Logout tracking

    Session management

    Beautiful formatted output with tables

Features
Feature	Description
🔐 User Tracking	Logs every command with timestamp and working directory
👥 Multi-user Support	Separate logs for each user
🛡️ Root Privileges	Root can view all users' logs
📊 Statistics	Command counts, login counts, logout counts
🎨 Formatted Output	Clean tables with proper alignment
🚀 Automatic	Starts automatically on login
📁 Centralized Storage	All logs in /var/log/user_commands/

Architecture
System Components
text

┌─────────────────────────────────────────────────────────────────────┐
│                     COMMAND LOGGER SYSTEM                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │   Profile    │───▶│   Logger     │───▶│    Log       │         │
│  │    Script    │    │   Script     │    │   Files      │         │
│  │              │    │              │    │              │         │
│  └──────────────┘    └──────────────┘    └──────────────┘         │
│         │                   │                   │                  │
│         ▼                   ▼                   ▼                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │ /etc/profile │    │ /usr/m1/     │    │ /var/log/    │         │
│  │ /user_command │    │ command_     │    │ user_        │         │
│  │ _logger.sh   │    │ logger.sh    │    │ commands/    │         │
│  └──────────────┘    └──────────────┘    └──────────────┘         │
│                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐         │
│  │   Monitor    │    │  Uninstall   │    │  Welcome     │         │
│  │   Script     │    │   Script     │    │  Message     │         │
│  │              │    │              │    │              │         │
│  └──────────────┘    └──────────────┘    └──────────────┘         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

File Structure
text

/usr/m1/
├── command_logger.sh          # Main logging script
└── monitor.sh                 # Admin monitoring tool

/etc/profile.d/
└── user_command_logger.sh     # Auto-start script

/var/log/user_commands/
├── master_commands.log        # All commands (all users)
└── users/
    ├── root_commands.log      # Root's commands
    ├── administrator_commands.log  # Administrator's commands
    └── [user]_commands.log    # Each user's commands

Installation
Prerequisites

    Linux OS (Ubuntu, CentOS, Debian, etc.)

    Bash 4.0+

    Root access (for system-wide installation)

    Basic permissions (for user installation)

Quick Installation
bash

# 1. Create installation directory
mkdir -p /usr/m1
cd /usr/m1

# 2. Create the main script
cat > command_logger.sh << 'EOF'
[Paste the script content here]
EOF

# 3. Create monitor script
cat > monitor.sh << 'EOF'
[Paste the monitor script content here]
EOF

# 4. Make scripts executable
chmod +x *.sh

# 5. Create profile script
cat > /etc/profile.d/user_command_logger.sh << 'EOF'
#!/bin/bash
if [ -f /usr/m1/command_logger.sh ]; then
    source /usr/m1/command_logger.sh
else
    echo "⚠️ Command logger not found"
fi
export -f show_my_logs count_my_commands show_user_logs
EOF

chmod 644 /etc/profile.d/user_command_logger.sh

# 6. Create log directory
mkdir -p /var/log/user_commands/users
chmod 777 /var/log/user_commands
chmod 777 /var/log/user_commands/users

# 7. Apply changes
source /usr/m1/command_logger.sh

Verification
bash

# Check if installed correctly
ls -la /usr/m1/command_logger.sh
ls -la /etc/profile.d/user_command_logger.sh
ls -la /var/log/user_commands/

# Test the logger
echo "test command"
show_my_logs



Configuration
Environment Variables
Variable	Description	Default
LOG_BASE	Base directory for logs	/var/log/user_commands
USER_LOG_DIR	User logs directory	$LOG_BASE/users
MASTER_LOG	Master log file	$LOG_BASE/master_commands.log
USER_LOG_FILE	Current user's log file	$USER_LOG_DIR/${USERNAME}_commands.log
Customization
Change Log Directory
bash

# Edit the script
vim /usr/m1/command_logger.sh

# Change this line:
LOG_BASE="/var/log/user_commands"

# To:
LOG_BASE="/custom/log/path"

Change Number of Commands Displayed
bash

# In show_my_logs function, change:
grep "^\[CMD\]" "$log_file" | tail -50

# To:
grep "^\[CMD\]" "$log_file" | tail -100

Disable Welcome Message
bash

# Comment out this section in main execution:
if [ -t 0 ] && [ -n "$PS1" ]; then
    show_welcome
fi

Commands Reference
For All Users
show_my_logs

Display your command history.

Syntax:
bash

show_my_logs

Example Output:
text

+--------------------------------------------------------------------------------------------------------------+
|  COMMAND HISTORY FOR administrator                                                                           |
+--------------------------------------------------------------------------------------------------------------+
| #     | Date & Time            | Directory                           | Command                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
| 1     | 2026-09-06 15:06:02   | /home/administrator                 | df -h                                    |
| 2     | 2026-09-06 15:06:06   | /home/administrator                 | free -m                                  |
| 3     | 2026-09-06 15:06:09   | /home/administrator                 | sudo -i                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+

+------------------------------------------------------------------------------+
|  STATISTICS                                                                  |
+------------------------------------------------------------------------------+
| Total Commands                 | 3                                        |
| Total Logins                   | 1                                        |
| Total Logouts                  | 0                                        |
+------------------------------------------------------------------------------+

count_my_commands

Count total commands executed by current user.

Syntax:
bash

count_my_commands

Example Output:
text

📊 Total commands executed: 42

debug_show_raw

Show raw log content for debugging purposes.

Syntax:
bash

debug_show_raw

Example Output:
text

=== RAW LOG CONTENT (last 10 lines) ===
[CMD] 2026-09-06 15:06:02 | /home/administrator | df -h
[CMD] 2026-09-06 15:06:06 | /home/administrator | free -m

=== COMMAND ENTRIES (last 5) ===
[CMD] 2026-09-06 15:06:02 | /home/administrator | df -h

=== TOTAL COMMANDS: 42

=== LOG DIRECTORY CONTENTS ===
total 16
-rw-r--r-- 1 root root 7329 سبت  6 15:37 root_commands.log
-rw-r--r-- 1 root root 2048 سبت  6 15:30 administrator_commands.log

For Root Only
show_user_logs

Display logs for specific users or all users.

Syntax:
bash

# Show all users
show_user_logs

# Show specific user
show_user_logs <username>

# Show root's own logs
show_user_logs root

Example Output (Specific User):
text

+--------------------------------------------------------------------------------------------------------------+
|  COMMAND HISTORY FOR administrator                                                                           |
+--------------------------------------------------------------------------------------------------------------+
| #     | Date & Time            | Directory                           | Command                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
| 1     | 2026-09-06 15:06:02   | /home/administrator                 | df -h                                    |
| 2     | 2026-09-06 15:06:06   | /home/administrator                 | free -m                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+

+------------------------------------------------------------------------------+
|  STATISTICS FOR administrator                                                |
+------------------------------------------------------------------------------+
| Total Commands                 | 2                                        |
| Total Logins                   | 1                                        |
| Total Logouts                  | 0                                        |
+------------------------------------------------------------------------------+

Example Output (All Users):
text

+--------------------------------------------------------------------------------------------------------------+
|  ALL USERS COMMAND HISTORY                                                                                   |
+--------------------------------------------------------------------------------------------------------------+

+--------------------------------------------------------------------------------------------------------------+
|  USER: root (Last 10 commands)                                                                               |
+--------------------------------------------------------------------------------------------------------------+
| #     | Date & Time            | Directory                           | Command                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
| 1     | 2026-09-06 15:00:00   | /root                               | ls -la                                   |
+-------+------------------------+-------------------------------------+------------------------------------------+
📊 Total commands for root: 42

+--------------------------------------------------------------------------------------------------------------+
|  USER: administrator (Last 10 commands)                                                                      |
+--------------------------------------------------------------------------------------------------------------+
| #     | Date & Time            | Directory                           | Command                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
| 1     | 2026-09-06 15:30:00   | /home/administrator                 | df -h                                    |
+-------+------------------------+-------------------------------------+------------------------------------------+
📊 Total commands for administrator: 15

Monitor Script
monitor.sh

Interactive admin monitoring tool with menu.

Usage:
bash

/usr/m1/monitor.sh

Menu Options:
text

+----------------------------------------------------------------------------------+
|  USER ACTIVITY MONITOR                                                           |
+----------------------------------------------------------------------------------+
| 1. Show Active Users                                                            |
| 2. Show Recent Commands (Last 20)                                              |
| 3. Show User Statistics                                                        |
| 4. Show Specific User Log                                                      |
| 5. Clean Old Logs (30+ days)                                                  |
| 6. Show Full Log (Last 30 entries)                                            |
| 7. Uninstall Logger                                                           |
| 0. Exit                                                                        |
+----------------------------------------------------------------------------------+

Monitor Commands
Option	Description	Example
1	Show currently logged-in users	who command output
2	Show last 20 commands from all users	Recent activity
3	Statistics per user	Command counts
4	View specific user's logs	Enter username
5	Clean logs older than 30 days	Automatic cleanup
6	Full log with all entries	Last 30 entries
7	Uninstall the logger	Complete removal
0	Exit monitor	-
Log Files Structure
Log File Format
Login Entry
text

[LOGIN] username | YYYY-MM-DD HH:MM:SS | Host: hostname | Server IP: IP | User IP: IP | Terminal: terminal | Session: PID

Command Entry
text

[CMD] YYYY-MM-DD HH:MM:SS | /path/to/directory | command with arguments

Logout Entry
text

[LOGOUT] username | YYYY-MM-DD HH:MM:SS | Session: PID

Example Log File
bash

[LOGIN] administrator | 2026-09-06 15:30:45 | Host: server01 | Server IP: 192.168.1.100 | User IP: 192.168.1.50 | Terminal: pts/0 | Session: 12345
[CMD] 2026-09-06 15:30:50 | /home/administrator | ls -la
[CMD] 2026-09-06 15:30:55 | /home/administrator | pwd
[CMD] 2026-09-06 15:31:00 | /home/administrator | cd /tmp
[CMD] 2026-09-06 15:31:05 | /tmp | whoami
[LOGOUT] administrator | 2026-09-06 15:35:00 | Session: 12345

Log Files Location
File	Path	Description
Master Log	/var/log/user_commands/master_commands.log	All commands from all users
Root Log	/var/log/user_commands/users/root_commands.log	Only root's commands
User Log	/var/log/user_commands/users/[username]_commands.log	Specific user's commands
User Guide
For Regular Users
1. First Login

When you log in, you'll see:
text

+----------------------------------------------------------------------------------+
|  WELCOME TO SERVER01                                                             |
+----------------------------------------------------------------------------------+
| Username                    | administrator                                      |
| Hostname                    | server01                                           |
| Server IP                   | 192.168.1.100                                      |
| Your IP                     | 192.168.1.50                                       |
| Login Time                  | 2026-09-06 15:30:45                                |
| Terminal                    | /dev/pts/0                                         |
| Session ID                  | 12345                                              |
+----------------------------------------------------------------------------------+

+----------------------------------------------------------------------------------+
|  SYSTEM INFORMATION                                                              |
+----------------------------------------------------------------------------------+
| OS                          | Ubuntu 22.04 LTS (Jammy) - x86_64                 |
| Kernel                      | 5.15.0-86-generic                                  |
| Uptime                      | up 3 days, 5 hours                                 |
| Load Average                | 0.05, 0.10, 0.15                                   |
| Memory Usage                | 2.3G/7.8G                                          |
| Disk Usage                  | 45G/100G (45%)                                     |
+----------------------------------------------------------------------------------+

2. Commands Available
bash

# View your command history
show_my_logs

# Count your commands
count_my_commands

# Debug raw logs
debug_show_raw

3. Working with Logs

View Last 10 Commands:
bash

show_my_logs

Search for Specific Command:
bash

show_my_logs | grep "sudo"

Count Commands:
bash

count_my_commands

Administrator Guide
For Root/Admin Users
1. Monitoring Users

View All Active Users:
bash

/usr/m1/monitor.sh
# Select option 1

View All User Statistics:
bash

/usr/m1/monitor.sh
# Select option 3

View Specific User Logs:
bash

# From command line
show_user_logs administrator

# From monitor
/usr/m1/monitor.sh
# Select option 4, then enter username

2. Analyzing Logs

Find Suspicious Activity:
bash

# Find all sudo commands
grep "sudo" /var/log/user_commands/users/*_commands.log

# Find commands run from unusual directories
grep "/tmp" /var/log/user_commands/users/*_commands.log

# Find failed commands (if exit codes were logged)
grep "Exit:1" /var/log/user_commands/users/*_commands.log

User Activity Report:
bash

# Create a report for a specific user
echo "=== User Activity Report for administrator ==="
echo "Commands: $(grep -c '^\[CMD\]' /var/log/user_commands/users/administrator_commands.log)"
echo "Logins: $(grep -c '^\[LOGIN\]' /var/log/user_commands/users/administrator_commands.log)"
echo "Logouts: $(grep -c '^\[LOGOUT\]' /var/log/user_commands/users/administrator_commands.log)"

Export Logs for Forensics:
bash

# Export all logs
tar -czf logs_$(date +%Y%m%d).tar.gz /var/log/user_commands/

# Export specific user
cp /var/log/user_commands/users/administrator_commands.log ./admin_$(date +%Y%m%d).log

3. Maintenance

Clean Old Logs:
bash

# From monitor
/usr/m1/monitor.sh
# Select option 5

# From command line
find /var/log/user_commands/ -name "*.log" -mtime +30 -delete

Set Up Log Rotation:
bash

# Add to logrotate
cat > /etc/logrotate.d/user_commands << 'EOF'
/var/log/user_commands/*.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 644 root root
}
EOF

# Test logrotate
logrotate -d /etc/logrotate.d/user_commands

Troubleshooting
Common Issues
Issue 1: "No logs found for user"

Symptoms:
bash

show_user_logs administrator
❌ No logs found for user: administrator

Solution:
bash

# 1. Check if user has logged in
ls -la /var/log/user_commands/users/

# 2. Create log file manually
touch /var/log/user_commands/users/administrator_commands.log
chmod 666 /var/log/user_commands/users/administrator_commands.log

# 3. Have user login and run commands
su - administrator
echo "test"
exit

Issue 2: Empty Table Output

Symptoms:
text

+-------+------------------------+-------------------------------------+------------------------------------------+
| #     | Date & Time            | Directory                           | Command                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
+-------+------------------------+-------------------------------------+------------------------------------------+

Solution:
bash

# 1. Check raw log content
debug_show_raw

# 2. Verify log format
cat /var/log/user_commands/users/$(whoami)_commands.log | head -5

# 3. Check if commands are being logged
grep -c "^\[CMD\]" /var/log/user_commands/users/$(whoami)_commands.log

# 4. Re-source the script
source /usr/m1/command_logger.sh

Issue 3: Permission Denied

Symptoms:
text

-bash: /var/log/user_commands/master_commands.log: Permission denied

Solution:
bash

# Fix permissions
sudo chmod 777 /var/log/user_commands
sudo chmod 777 /var/log/user_commands/users
sudo chmod 666 /var/log/user_commands/*.log
sudo chmod 666 /var/log/user_commands/users/*.log

Issue 4: Logger Not Starting Automatically

Symptoms:

    No welcome message on login

    show_my_logs command not found

Solution:
bash

# 1. Check profile script
ls -la /etc/profile.d/user_command_logger.sh

# 2. Check if it's sourced
grep "user_command_logger" /etc/profile

# 3. Add if missing
echo "source /etc/profile.d/user_command_logger.sh" >> /etc/profile

# 4. Check script permissions
chmod 644 /etc/profile.d/user_command_logger.sh

How to Uninstall the Command Logger System
Methods to Uninstall
Method 1: Using the Uninstall Script (Recommended)
Step 1: Download/Create the Uninstall Script
bash

# Create the uninstall script
sudo nano /usr/m1/uninstall.

Method 2: Using Monitor Script (If Available)
bash

# Run the monitor script
sudo /usr/m1/monitor.sh

# Select option 7 from the menu
# Follow the prompts to uninstall

Method 3: Manual Uninstall (Complete)
bash

#!/bin/bash
# Complete manual uninstall

echo "========================================="
echo "🗑️  Uninstalling Command Logger..."
echo "========================================="

# 1. Remove scripts from /usr/m1
echo "Removing scripts from /usr/m1..."
sudo rm -f /usr/m1/command_logger.sh
sudo rm -f /usr/m1/monitor.sh
sudo rm -f /usr/m1/uninstall.sh

# 2. Remove profile script
echo "Removing profile script..."
sudo rm -f /etc/profile.d/user_command_logger.sh

# 3. Remove log directory (with confirmation)
echo ""
echo -n "Remove all log files? (y/N): "
read remove_logs
if [[ "$remove_logs" == "y" ]] || [[ "$remove_logs" == "Y" ]]; then
    echo "Removing /var/log/user_commands..."
    sudo rm -rf /var/log/user_commands
    echo "✅ Logs removed"
else
    echo "📁 Logs kept at /var/log/user_commands"
fi

# 4. Remove cron jobs
echo "Removing cron jobs..."
crontab -l 2>/dev/null | grep -v "monitor.sh\|command_logger" | crontab -

# 5. Remove aliases if any
echo "Removing aliases..."
if grep -q "show_my_logs" ~/.bashrc 2>/dev/null; then
    sed -i '/show_my_logs/d' ~/.bashrc
    sed -i '/count_my_commands/d' ~/.bashrc
fi

# 6. Remove from profile
echo "Cleaning up profile..."
if grep -q "user_command_logger.sh" /etc/profile 2>/dev/null; then
    sudo sed -i '/user_command_logger.sh/d' /etc/profile
fi

echo "========================================="
echo "✅ Uninstall complete!"
echo ""
echo "📌 To complete removal:"
echo "  - Close and reopen your terminal"
echo "  - OR start a new session"
echo "========================================="

Method 4: Quick One-Liner Uninstall
bash

# Complete uninstall in one command (removes everything)
sudo rm -rf /usr/m1/command_logger.sh /usr/m1/monitor.sh /usr/m1/uninstall.sh /etc/profile.d/user_command_logger.sh /var/log/user_commands && crontab -l 2>/dev/null | grep -v "monitor.sh" | crontab - && echo "✅ Uninstall complete!"

What Gets Removed
Files Removed:
text

✅ /usr/m1/command_logger.sh
✅ /usr/m1/monitor.sh
✅ /usr/m1/uninstall.sh
✅ /etc/profile.d/user_command_logger.sh
✅ /var/log/user_commands/ (optional)
✅ Any backup files (*.bak)

Cron Jobs Removed:
text

✅ 0 2 * * * /usr/m1/monitor.sh clean_old_logs
✅ Any job containing "monitor.sh" or "command_logger"

Environment Cleanup:
text

✅ Aliases and functions from shell (show_my_logs, count_my_commands)
✅ Profile entries for auto-start

Verification of Uninstall
Check if Removed Successfully
bash

# Check if scripts are gone
ls -la /usr/m1/command_logger.sh 2>/dev/null
ls -la /etc/profile.d/user_command_logger.sh 2>/dev/null

# Check if commands still work
show_my_logs 2>/dev/null
count_my_commands 2>/dev/null

# Check if cron jobs are gone
crontab -l | grep -i "monitor\|logger"

# Check if log directory is removed
ls -la /var/log/user_commands 2>/dev/null

Expected Output After Successful Uninstall
bash

# Check scripts
$ ls -la /usr/m1/command_logger.sh
ls: cannot access '/usr/m1/command_logger.sh': No such file or directory

# Check commands
$ show_my_logs
bash: show_my_logs: command not found

# Check cron
$ crontab -l | grep monitor
(No output)

# Check logs
$ ls -la /var/log/user_commands
ls: cannot access '/var/log/user_commands': No such file or directory

Post-Uninstall Cleanup
Clear Shell Cache
bash

# Reload profile to remove functions
source /etc/profile 2>/dev/null

# Clear bash cache
hash -r

# Start a new session (logout and login)
exit

Remove from User's .bashrc

If commands were added manually:
bash

# Remove from root's .bashrc
sed -i '/user_command_logger/d' ~/.bashrc
sed -i '/show_my_logs/d' ~/.bashrc
sed -i '/count_my_commands/d' ~/.bashrc

# Remove from other users
for user in $(getent passwd | cut -d: -f1 | grep -v "root\|nobody"); do
    sed -i '/user_command_logger/d' /home/$user/.bashrc
    sed -i '/show_my_logs/d' /home/$user/.bashrc
    sed -i '/count_my_commands/d' /home/$user/.bashrc
done

Troubleshooting Uninstall
Issue: "Permission denied" during uninstall

Solution:
bash

# Run as root
sudo su -
# Then run uninstall commands

Issue: Cron jobs not removed

Solution:
bash

# Manually edit crontab
sudo crontab -e
# Remove any lines containing "monitor.sh" or "command_logger"

# Or clear entire crontab
sudo crontab -r

Issue: Commands still work after uninstall

Solution:
bash

# Start new session
exit
# Login again

# Or manually remove functions
unset -f show_my_logs count_my_commands show_user_logs debug_show_raw

Issue: Log directory still exists

Solution:
bash

# Remove directory completely
sudo rm -rf /var/log/user_commands

# Or remove only log files but keep directory
sudo find /var/log/user_commands -name "*.log" -delete

Summary
Quick Uninstall Command
bash

# Most complete uninstall
sudo /usr/m1/uninstall.sh  # If you have the script
# OR
sudo rm -rf /usr/m1/command_logger.sh /usr/m1/monitor.sh /usr/m1/uninstall.sh /etc/profile.d/user_command_logger.sh /var/log/user_commands && crontab -l 2>/dev/null | grep -v "monitor.sh" | crontab - && echo "✅ Uninstalled"

After Uninstall
    Close and reopen your terminal
    Or start a new shell session
    Verify all components are removed
    Check that functions are no longer available

Important Notes
    ⚠️ This will remove all command logs (if you choose to)
    ⚠️ You cannot undo the uninstall
    ⚠️ Make sure you have backups of important logs
    ⚠️ You may need to restart your session for changes to take effect


Security
Access Control
Resource	Read Access	Write Access	Execute Access
/usr/m1/command_logger.sh	Root	Root	All Users
/var/log/user_commands/	All	Root	All
/var/log/user_commands/users/	All	All	All
User's own log file	User	User	-
Master log	Root	Root	-


Conclusion

The Command Logger System provides a robust, secure, and efficient way to monitor user activities on Linux systems. With its comprehensive logging, easy-to-use interface, and flexible configuration options, it's an essential tool for system administrators.
Quick Reference Card
bash

# User Commands
show_my_logs          # View your command history
count_my_commands     # Count your commands
debug_show_raw        # View raw logs

# Root Commands
show_user_logs        # View all users
show_user_logs user   # View specific user

# System Commands
tail -f /var/log/user_commands/master_commands.log  # Real-time monitoring
ls -la /var/log/user_commands/users/               # List user logs
grep "sudo" /var/log/user_commands/users/*         # Search for sudo commands

Support

For issues or questions:
    Check the Troubleshooting section
    Review logs using debug_show_raw
    Verify system permissions
    Ensure script is properly sourced
    send email to: mr.php0@gmail.com

Documentation Version: 1.0
Last Updated: 2026-09-06

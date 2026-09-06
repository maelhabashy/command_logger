Command Logger System - Complete Documentation
📋 Table of Contents

    Overview

    Features

    Installation

    Architecture

    Usage Guide

    Commands Reference

    Configuration

    Troubleshooting

    Security

    FAQ

Overview

The Command Logger System is a comprehensive Bash-based solution for monitoring and logging user activities on Linux servers. It automatically records all commands executed by users, along with timestamps, working directories, and session information.
Purpose

    Security Auditing: Track who executed what commands and when

    Compliance: Meet regulatory requirements for user activity logging

    Troubleshooting: Identify which commands caused system issues

    Forensics: Investigate security incidents with detailed logs

    User Monitoring: Monitor user behavior and system usage patterns

Key Benefits

    ✅ Automatic Logging: No user intervention required

    ✅ Multi-User Support: Separate logs for each user

    ✅ Centralized Management: Root can view all user logs

    ✅ Lightweight: Minimal performance impact

    ✅ Secure: Proper permissions and access controls

Features
Core Features
Feature	Description
Automatic Command Logging	All commands are logged automatically
User-Specific Logs	Each user has a separate log file
Master Log	Centralized log for all users
Timestamp Tracking	Precise date and time for each command
Directory Tracking	Working directory for each command
Login/Logout Tracking	Session start and end times
IP Address Logging	Both server and client IP addresses
Session ID Tracking	Unique session identifier
Admin Features (Root Only)
Feature	Description
View All Users	See logs for all users
View Specific User	View logs for any user
User Statistics	Command counts and activity metrics
Log Cleanup	Remove logs older than 30 days
Full Log View	Complete history with all events
User Features
Feature	Description
View Own Logs	See personal command history
Count Commands	Total number of commands executed
Debug View	Raw log viewing for troubleshooting
Installation
Prerequisites

    Linux operating system (Ubuntu, CentOS, RHEL, etc.)

    Bash shell

    Root or sudo access for installation

    Required permissions: write access to /var/log

Step-by-Step Installation
1. Create Installation Directory
bash

sudo mkdir -p /usr/m1
cd /usr/m1

2. Create the Main Script
bash

sudo nano /usr/m1/command_logger.sh

Paste the complete script content and save.
3. Make Script Executable
bash

sudo chmod +x /usr/m1/command_logger.sh

4. Create Profile Script
bash

sudo nano /etc/profile.d/user_command_logger.sh

Add the following content:
bash

#!/bin/bash
if [ -f /usr/m1/command_logger.sh ]; then
    source /usr/m1/command_logger.sh
fi
export -f show_my_logs count_my_commands show_user_logs

5. Set Proper Permissions
bash

sudo chmod 644 /etc/profile.d/user_command_logger.sh
sudo mkdir -p /var/log/user_commands/users
sudo chmod 777 /var/log/user_commands
sudo chmod 777 /var/log/user_commands/users

6. Enable in Current Session
bash

source /usr/m1/command_logger.sh

7. Test Installation
bash

# Test logging
echo "test command"
ls -la

# View logs
show_my_logs

# Check log files
ls -la /var/log/user_commands/users/

Automatic Startup

The system automatically enables logging for all users through /etc/profile.d/user_command_logger.sh, which is sourced on every login.
Architecture
Directory Structure
text

/usr/m1/
└── command_logger.sh          # Main logging script

/etc/profile.d/
└── user_command_logger.sh     # System-wide profile integration

/var/log/user_commands/
├── master_commands.log        # Consolidated log for all users
└── users/
    ├── root_commands.log      # Root's command history
    ├── administrator_commands.log  # Administrator's history
    └── [user]_commands.log    # Each user's individual log

Log Format
Command Log Format
text

[CMD] 2026-09-06 15:31:04 | /usr/m1 | source /usr/m1/command_logger.sh

Fields:

    [CMD] - Log entry type (Command)

    2026-09-06 15:31:04 - Timestamp (YYYY-MM-DD HH:MM:SS)

    /usr/m1 - Working directory

    source /usr/m1/command_logger.sh - The actual command

Login Log Format
text

[LOGIN] administrator | 2026-09-06 15:30:45 | Host: server01 | Server IP: 192.168.1.100 | User IP: 192.168.1.50 | Terminal: /dev/pts/0 | Session: 12345

Logout Log Format
text

[LOGOUT] administrator | 2026-09-06 18:45:30 | Session: 12345

Data Flow
text

User Command → History Command → DEBUG Trap → log_command() → Write to Log Files
         ↓
    Login/Logout → log_login()/log_logout() → Write to Log Files

Usage Guide
For Regular Users
View Your Command History
bash

show_my_logs

Output Example:
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
| Total Commands                 | 21                                       |
| Total Logins                   | 8                                        |
| Total Logouts                  | 7                                        |
+------------------------------------------------------------------------------+

Count Your Commands
bash

count_my_commands

Output:
text

📊 Total commands executed: 21

Debug Raw Log
bash

debug_show_raw

Output:
text

=== RAW LOG CONTENT (last 10 lines) ===
[CMD] 2026-09-06 15:31:04 | /usr/m1 | source /usr/m1/command_logger.sh
[CMD] 2026-09-06 15:31:12 | /usr/m1 | show_my_logs
...

=== COMMAND ENTRIES (last 5) ===
[CMD] 2026-09-06 15:31:04 | /usr/m1 | source /usr/m1/command_logger.sh
...

=== TOTAL COMMANDS: 21

For Root User (Administrator)
View All Users
bash

show_user_logs

Output:
text

+--------------------------------------------------------------------------------------------------------------+
|  ALL USERS COMMAND HISTORY                                                                                   |
+--------------------------------------------------------------------------------------------------------------+

+--------------------------------------------------------------------------------------------------------------+
|  USER: root (Last 10 commands)                                                                               |
+--------------------------------------------------------------------------------------------------------------+
| #     | Date & Time            | Directory                           | Command                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
| 1     | 2026-09-06 15:06:02   | /root                               | systemctl restart nginx                  |
| 2     | 2026-09-06 15:06:06   | /root                               | tail -f /var/log/nginx/error.log         |
+-------+------------------------+-------------------------------------+------------------------------------------+
📊 Total commands for root: 45

+--------------------------------------------------------------------------------------------------------------+
|  USER: administrator (Last 10 commands)                                                                      |
+--------------------------------------------------------------------------------------------------------------+
| #     | Date & Time            | Directory                           | Command                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
| 1     | 2026-09-06 15:06:02   | /home/administrator                 | df -h                                    |
| 2     | 2026-09-06 15:06:06   | /home/administrator                 | free -m                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
📊 Total commands for administrator: 21

View Specific User
bash

show_user_logs username

Example:
bash

show_user_logs administrator

View Root's Own Logs
bash

show_my_logs

Commands Reference
Complete Command List
Command	Permission	Description	Syntax
show_my_logs	All Users	Display current user's command history	show_my_logs
count_my_commands	All Users	Show total command count for current user	count_my_commands
debug_show_raw	All Users	Display raw log content for debugging	debug_show_raw
show_user_logs	Root Only	View all users or specific user's logs	show_user_logs [username]
Detailed Command Reference
show_my_logs

Purpose: Display command history for the current user

Syntax:
bash

show_my_logs

Features:

    Shows last 50 commands

    Includes timestamp, directory, and command

    Displays statistics (total commands, logins, logouts)

Example Output:
bash

administrator@server:~$ show_my_logs
+--------------------------------------------------------------------------------------------------------------+
|  COMMAND HISTORY FOR administrator                                                                           |
+--------------------------------------------------------------------------------------------------------------+
| #     | Date & Time            | Directory                           | Command                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+
| 1     | 2026-09-06 10:30:15   | /home/administrator                 | ls -la                                   |
| 2     | 2026-09-06 10:30:20   | /home/administrator                 | cd /tmp                                  |
+-------+------------------------+-------------------------------------+------------------------------------------+

show_user_logs

Purpose: View logs for all users or a specific user (Root only)

Syntax:
bash

# Show all users
show_user_logs

# Show specific user
show_user_logs username

Examples:
bash

# Show all users
root@server:~# show_user_logs

# Show administrator's logs
root@server:~# show_user_logs administrator

# Show root's own logs (alternative)
root@server:~# show_user_logs root

count_my_commands

Purpose: Display total number of commands executed by current user

Syntax:
bash

count_my_commands

Output:
bash

administrator@server:~$ count_my_commands
📊 Total commands executed: 21

debug_show_raw

Purpose: Display raw log content for troubleshooting

Syntax:
bash

debug_show_raw

Output:
text

=== RAW LOG CONTENT (last 10 lines) ===
[CMD] 2026-09-06 15:31:04 | /usr/m1 | source /usr/m1/command_logger.sh
...
=== COMMAND ENTRIES (last 5) ===
[CMD] 2026-09-06 15:31:04 | /usr/m1 | source /usr/m1/command_logger.sh
...
=== TOTAL COMMANDS: 21
=== LOG DIRECTORY CONTENTS ===
total 16
drwxr-xr-x 2 root root 4096 سبت  6 15:15 .
drwxr-xr-x 3 root root 4096 سبت  6 15:15 ..
-rw-r--r-- 1 root root 7329 سبت  6 15:37 root_commands.log

Configuration
Log Location
bash

# Main directory
/var/log/user_commands/

# User-specific logs
/var/log/user_commands/users/

# Master log
/var/log/user_commands/master_commands.log

Permission Settings
bash

# Directory permissions
/var/log/user_commands/     - 755 (rwxr-xr-x)
/var/log/user_commands/users/ - 777 (rwxrwxrwx)

# File permissions
*.log                       - 666 (rw-rw-rw-)

Log Rotation

To prevent logs from growing too large, set up logrotate:
bash

# Create logrotate configuration
sudo nano /etc/logrotate.d/user_commands

# Add content:
/var/log/user_commands/*.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 644 root root
    postrotate
        systemctl kill -s HUP rsyslog >/dev/null 2>&1 || true
    endscript
}

# Test the configuration
sudo logrotate -d /etc/logrotate.d/user_commands

Custom Log Directory

To change the log directory, modify the LOG_BASE variable in command_logger.sh:
bash

# Change this line
LOG_BASE="/var/log/user_commands"

# To custom location
LOG_BASE="/custom/path/logs"

Troubleshooting
Common Issues and Solutions
Issue 1: No logs are being recorded

Symptoms:

    show_my_logs shows empty table

    No files in /var/log/user_commands/users/

Solutions:
bash

# Check if logging is enabled
echo $PROMPT_COMMAND

# Source the script manually
source /usr/m1/command_logger.sh

# Check directory permissions
ls -la /var/log/user_commands/users/

# Create directories with proper permissions
sudo mkdir -p /var/log/user_commands/users
sudo chmod 777 /var/log/user_commands/users

# Test with debug
debug_show_raw

Issue 2: Permission Denied

Symptoms:
text

/var/log/user_commands/master_commands.log: Permission denied

Solutions:
bash

# Fix permissions
sudo chmod 777 /var/log/user_commands
sudo chmod 777 /var/log/user_commands/users
sudo touch /var/log/user_commands/master_commands.log
sudo chmod 666 /var/log/user_commands/master_commands.log

# Check ownership
ls -la /var/log/user_commands/

Issue 3: Table is empty but commands exist

Symptoms:

    Statistics show commands but table is empty

Solutions:
bash

# Check raw log format
debug_show_raw

# Check log file content
cat /var/log/user_commands/users/$(whoami)_commands.log

# Verify command format
grep "^\[CMD\]" /var/log/user_commands/users/$(whoami)_commands.log | head -1

Issue 4: Logs not showing for other users

Symptoms:
text

❌ No logs found for user: username

Solutions:
bash

# Check if user logs exist
ls -la /var/log/user_commands/users/

# Create log file for user
sudo touch /var/log/user_commands/users/username_commands.log
sudo chmod 666 /var/log/user_commands/users/username_commands.log

# Ensure user is running the logger
su - username
source /usr/m1/command_logger.sh
echo "test"
exit

Issue 5: Script not starting on login

Symptoms:

    No welcome message

    Commands not being logged

Solutions:
bash

# Check profile script
cat /etc/profile.d/user_command_logger.sh

# Reinstall profile script
sudo tee /etc/profile.d/user_command_logger.sh > /dev/null << 'EOF'
#!/bin/bash
if [ -f /usr/m1/command_logger.sh ]; then
    source /usr/m1/command_logger.sh
fi
export -f show_my_logs count_my_commands show_user_logs
EOF

sudo chmod 644 /etc/profile.d/user_command_logger.sh

# Logout and login again
exit

Debug Mode

Enable debug output in the script:
bash

# Add debug lines in show_my_logs function
echo "DEBUG: Processing line: $line" >&2

Log Analysis Commands
bash

# Count commands for a user
grep -c "^\[CMD\]" /var/log/user_commands/users/username_commands.log

# Show last 10 commands
tail -10 /var/log/user_commands/users/username_commands.log

# Search for specific command
grep "sudo" /var/log/user_commands/users/username_commands.log

# Show commands between dates
grep "2026-09-06 10:" /var/log/user_commands/users/username_commands.log

# Count logins
grep -c "^\[LOGIN\]" /var/log/user_commands/users/username_commands.log

# Show unique commands
grep "^\[CMD\]" /var/log/user_commands/users/username_commands.log | awk -F'|' '{print $4}' | sort | uniq -c | sort -nr

Security
Access Control
Resource	Read Access	Write Access	Execute Access
/usr/m1/command_logger.sh	Root	Root	All Users
/var/log/user_commands/	All	Root	All
/var/log/user_commands/users/	All	All	All
User's own log file	User	User	-
Master log	Root	Root	-
Security Best Practices

    Regular Log Review: Periodically review logs for suspicious activity
    bash

    # Weekly review
    grep "sudo\|passwd\|chmod\|chown" /var/log/user_commands/users/*_commands.log

    Log Backup: Backup logs regularly
    bash

    # Daily backup
    tar -czf /backup/logs_$(date +%Y%m%d).tar.gz /var/log/user_commands/

    Monitor Log Size: Set up alerts for large logs
    bash

    # Check log size
    du -sh /var/log/user_commands/

    Restrict Access: Limit who can view other users' logs
    bash

    # Only root can see other users
    usermod -a -G root adminuser

    Audit Log Integrity: Verify logs haven't been tampered
    bash

    # Compare with backup
    diff /backup/logs/ /var/log/user_commands/

Privacy Considerations

    Users can only view their own logs

    Root has complete access for administrative purposes

    IP addresses are logged for security auditing

    Session IDs help track user activities

FAQ
General Questions

Q: Does the logger affect system performance?
A: No, the logger has minimal impact as it only appends to log files and uses lightweight Bash operations.

Q: Can users delete their own logs?
A: No, users cannot delete logs. Only root can manage log files.

Q: How long are logs kept?
A: By default, logs are kept indefinitely. Use logrotate to manage retention.

Q: Does it work with all shells?
A: It works with Bash. For other shells, manual sourcing may be required.
Technical Questions

Q: How are commands captured?
A: Using the DEBUG trap in Bash, which captures every command before execution.

Q: What about commands with pipes?
A: The logger captures the entire command line including pipes and redirects.

Q: Are background jobs logged?
A: Yes, all commands are logged regardless of foreground/background execution.

Q: Does it log failed commands?
A: Yes, all commands are logged, including those that fail.

Q: What about interactive commands (vi, vim)?
A: The launch of interactive commands is logged, but the internal editor commands are not.
Troubleshooting Questions

Q: Why aren't my commands being logged?
A: Check if the logger is sourced (source /usr/m1/command_logger.sh), verify permissions, and ensure the profile script is installed.

Q: Can I log commands for existing sessions?
A: Yes, manually source the script: source /usr/m1/command_logger.sh

Q: How do I change the log location?
A: Modify LOG_BASE in command_logger.sh and update permissions.

Q: Why do I get "Permission denied" errors?
A: Check directory permissions and ensure proper write access to /var/log/user_commands/users/.

Q: Can I see logs in real-time?
A: Yes, use tail -f /var/log/user_commands/master_commands.log
Advanced Configuration
Custom Logging Filters

To exclude certain commands:
bash

# In log_command function
if [[ "$command" == "ls" ]] || [[ "$command" == "clear" ]]; then
    return
fi

Custom Log Format

To change the log format:
bash

# Change this line
echo "[CMD] $command_time | $pwd_path | $command"

# To include username
echo "[CMD] $USERNAME | $command_time | $pwd_path | $command"

Multi-Server Setup

For centralized logging:
bash

# Send logs to remote server
echo "[CMD] $command_time | $pwd_path | $command" | nc -w 1 logserver 514

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

Documentation Version: 1.0
Last Updated: 2026-09-06

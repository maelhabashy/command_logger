# 🔐 Command Logger

> A lightweight Bash-based Linux command auditing and user activity monitoring system.

**Command Logger** records shell activity on Linux servers, including executed commands, timestamps, working directories, login/logout events, session information, and user activity.

It is designed for **Linux system administrators, security teams, DevOps engineers, and server operators** who need a simple way to monitor and audit shell activity without deploying a full SIEM solution.

---

## ✨ Features

* 🔐 **Command Logging**

  * Records commands executed by users.
  * Stores command timestamp and working directory.
  * Maintains per-user command history.

* 👥 **Multi-User Support**

  * Separate log files for each user.
  * Centralized master log containing activity from all users.

* 🔑 **Login / Logout Tracking**

  * Records login events.
  * Records logout events.
  * Captures session and terminal information.

* 🖥️ **System Information**

  * Displays hostname.
  * Displays server IP.
  * Displays user IP when available.
  * Shows OS, kernel, uptime, memory, disk, and load information.

* 📊 **Statistics**

  * Total commands.
  * Login count.
  * Logout count.
  * Per-user activity statistics.

* 🛡️ **Administrator Monitoring**

  * View activity for individual users.
  * View activity across all users.
  * Search logs for suspicious commands.
  * Review recent activity.

* 🎨 **Readable CLI Output**

  * Formatted tables.
  * Human-readable command history.
  * Interactive monitoring menu.

* 🚀 **Automatic Startup**

  * Logger is loaded through `/etc/profile.d/`.
  * User activity is automatically monitored when a shell session starts.

* 🧹 **Log Cleanup**

  * Supports cleaning old logs.
  * Monitoring tools include cleanup functionality.

* 📦 **Easy Installation**

  * Installation script included.
  * Uninstallation script included.

---

# 🏗️ Architecture

```text
                         Linux Server
                              │
                              │
                    ┌─────────▼─────────┐
                    │    User Login     │
                    └─────────┬─────────┘
                              │
                              ▼
                  /etc/profile.d/
                user_command_logger.sh
                              │
                              ▼
                    command_logger.sh
                              │
             ┌────────────────┼────────────────┐
             │                │                │
             ▼                ▼                ▼
        Login Event      Command Event    Logout Event
             │                │                │
             └────────────────┼────────────────┘
                              │
                              ▼
                  /var/log/user_commands/
                              │
             ┌────────────────┴────────────────┐
             │                                 │
             ▼                                 ▼
      master_commands.log              users/
                                       │
                         ┌─────────────┼─────────────┐
                         │             │             │
                         ▼             ▼             ▼
                    root.log      user1.log      user2.log
```

---

# 📁 Project Structure

```text
command_logger/
├── command_logger.sh
├── monitor.sh
├── UserMon.sh
├── install.sh
├── uninstall.sh
├── Commands_Reference.txt
├── README.md
├── readme.md
└── LICENSE
```

## Main Components

| File                     | Purpose                                   |
| ------------------------ | ----------------------------------------- |
| `command_logger.sh`      | Main command logging engine               |
| `monitor.sh`             | Interactive administrator monitoring tool |
| `UserMon.sh`             | User monitoring functionality             |
| `install.sh`             | Installation and setup                    |
| `uninstall.sh`           | Removes the logger from the system        |
| `Commands_Reference.txt` | Command reference                         |
| `README.md`              | Project documentation                     |
| `LICENSE`                | Project license                           |

---

# 📂 Log Storage

By default, logs are stored under:

```text
/var/log/user_commands/
```

Structure:

```text
/var/log/user_commands/
├── master_commands.log
└── users/
    ├── root_commands.log
    ├── administrator_commands.log
    ├── user1_commands.log
    └── user2_commands.log
```

### Master Log

```text
/var/log/user_commands/master_commands.log
```

Contains command activity from all users.

### Per-User Logs

```text
/var/log/user_commands/users/<username>_commands.log
```

Contains activity associated with a specific user.

---

# 📝 Log Format

Command Logger uses a simple structured text format.

### Login Event

```text
[LOGIN] administrator | 2026-09-06 15:30:45 | Host: server01 | Server IP: 192.168.1.100 | User IP: 192.168.1.50 | Terminal: pts/0 | Session: 12345
```

### Command Event

```text
[CMD] 2026-09-06 15:30:50 | /home/administrator | ls -la
```

### Logout Event

```text
[LOGOUT] administrator | 2026-09-06 15:35:00 | Session: 12345
```

This makes the logs easy to process using standard Linux tools such as:

```bash
grep
awk
sed
cut
sort
uniq
tail
```

---

# ⚙️ Requirements

The project is designed for Linux systems with:

* Bash 4.0+
* Linux shell environment
* Root/sudo access for system-wide installation
* Standard Linux utilities

It can be used on common Linux distributions such as:

* Ubuntu
* Debian
* RHEL
* CentOS
* Rocky Linux
* AlmaLinux
* Oracle Linux
* Other Bash-compatible Linux systems

---

# 🚀 Installation

## Option 1 — Clone the Repository

```bash
git clone https://github.com/maelhabashy/command_logger.git
cd command_logger
```

Make the scripts executable:

```bash
chmod +x *.sh
```

Run the installer:

```bash
sudo ./install.sh
```

After installation, start a new shell session:

```bash
exit
```

Then reconnect to the server.

---

# 🔎 Verify Installation

Check the main installation directory:

```bash
ls -la /usr/m1/
```

Check the profile integration:

```bash
ls -la /etc/profile.d/user_command_logger.sh
```

Check the log directory:

```bash
ls -la /var/log/user_commands/
```

You should see the logging directory and associated files.

---

# 🧪 Test the Logger

Run a few commands:

```bash
pwd
whoami
hostname
df -h
free -m
```

Then check your command history:

```bash
show_my_logs
```

Count your commands:

```bash
count_my_commands
```

For raw debugging information:

```bash
debug_show_raw
```

---

# 👤 User Commands

## View Your Command History

```bash
show_my_logs
```

Example:

```text
+------------------------------------------------------------------------------------------------+
| COMMAND HISTORY FOR administrator                                                              |
+------------------------------------------------------------------------------------------------+
| # | Date & Time         | Directory             | Command                                      |
+---+---------------------+----------------------+----------------------------------------------+
| 1 | 2026-09-06 15:06:02 | /home/administrator  | df -h                                        |
| 2 | 2026-09-06 15:06:06 | /home/administrator  | free -m                                      |
| 3 | 2026-09-06 15:06:09 | /home/administrator  | sudo -i                                      |
+------------------------------------------------------------------------------------------------+
```

---

## Count Your Commands

```bash
count_my_commands
```

Example:

```text
📊 Total commands executed: 42
```

---

## Debug Raw Logs

```bash
debug_show_raw
```

Useful when troubleshooting logging or formatting problems.

---

# 👑 Administrator Commands

Administrators/root users can inspect activity for other users.

## View All Users

```bash
show_user_logs
```

## View a Specific User

```bash
show_user_logs administrator
```

## View Root Logs

```bash
show_user_logs root
```

---

# 📊 Monitoring Tool

Command Logger includes an interactive monitoring tool:

```bash
sudo /usr/m1/monitor.sh
```

The monitoring menu provides options such as:

```text
+-------------------------------------------------------------+
|                  USER ACTIVITY MONITOR                      |
+-------------------------------------------------------------+
| 1. Show Active Users                                        |
| 2. Show Recent Commands                                    |
| 3. Show User Statistics                                    |
| 4. Show Specific User Log                                  |
| 5. Clean Old Logs                                          |
| 6. Show Full Log                                           |
| 7. Uninstall Logger                                        |
| 0. Exit                                                    |
+-------------------------------------------------------------+
```

This gives administrators a convenient CLI interface instead of manually searching log files.

---

# 🔍 Security / Activity Investigation

Because the logs are plain text, standard Linux tools can be used for investigation.

## Search for sudo commands

```bash
grep "sudo" /var/log/user_commands/users/*_commands.log
```

## Search for commands executed from `/tmp`

```bash
grep "/tmp" /var/log/user_commands/users/*_commands.log
```

## Search for a specific command

```bash
grep "systemctl" /var/log/user_commands/users/*_commands.log
```

## View the latest activity

```bash
tail -50 /var/log/user_commands/master_commands.log
```

## Follow the master log in real time

```bash
tail -f /var/log/user_commands/master_commands.log
```

---

# 📦 Log Export

Export all logs:

```bash
tar -czf logs_$(date +%Y%m%d).tar.gz \
    /var/log/user_commands/
```

Export a specific user's log:

```bash
cp /var/log/user_commands/users/administrator_commands.log \
   ./administrator_$(date +%Y%m%d).log
```

---

# 🧹 Log Cleanup

The monitoring tool supports cleanup of old logs.

You can also manually remove logs older than 30 days:

```bash
find /var/log/user_commands/ \
    -name "*.log" \
    -mtime +30 \
    -delete
```

> **Warning:** Deleting logs may remove information required for auditing or forensic investigation. Make sure your retention policy is defined before enabling automatic deletion.

---

# 🔄 Log Rotation

For production environments, configure `logrotate` to prevent log files from growing indefinitely.

Example:

```bash
sudo nano /etc/logrotate.d/user_commands
```

Example configuration:

```text
/var/log/user_commands/*.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
    create 644 root root
}
```

Test the configuration:

```bash
sudo logrotate -d /etc/logrotate.d/user_commands
```

---

# ⚙️ Configuration

The default log directory is:

```text
/var/log/user_commands
```

The main environment variables include:

| Variable        | Description             |
| --------------- | ----------------------- |
| `LOG_BASE`      | Base directory for logs |
| `USER_LOG_DIR`  | Per-user log directory  |
| `MASTER_LOG`    | Master log file         |
| `USER_LOG_FILE` | Current user's log file |

Default:

```bash
LOG_BASE="/var/log/user_commands"
```

You can customize the location according to your server's logging policy.

---

# 🔐 Security Considerations

Command logging can contain **sensitive information**.

Commands may include:

```text
passwords
tokens
API keys
database credentials
private paths
internal hostnames
security commands
```

For example:

```bash
mysql -u root -pMyPassword
```

could result in sensitive information being written to logs.

Therefore:

### ⚠️ Do not treat command logs as harmless data.

Protect them using appropriate:

* File permissions
* Access controls
* Log retention policies
* Backup policies
* Encryption where required
* Monitoring and auditing policies

For production systems, avoid overly permissive permissions such as:

```bash
chmod 777
```

on sensitive log directories.

Use the minimum permissions required by your logging architecture.

---

# 🛡️ Recommended Production Approach

For production servers, consider:

```text
Linux Server
     │
     ▼
Command Logger
     │
     ▼
Local Logs
     │
     ├── Log Rotation
     │
     ├── Retention Policy
     │
     └── Secure Permissions
              │
              ▼
        Central Log System
              │
       ┌──────┴──────┐
       ▼             ▼
     SIEM         Monitoring
```

Examples of systems that can consume centralized logs include:

* ELK / Elastic Stack
* Graylog
* Splunk
* Wazuh
* Loki
* SIEM platforms

---

# 🐛 Troubleshooting

## `show_my_logs: command not found`

Check:

```bash
ls -la /etc/profile.d/user_command_logger.sh
```

Then reload the profile:

```bash
source /etc/profile
```

Or start a new SSH session.

---

## No Logs Are Being Generated

Check:

```bash
ls -la /var/log/user_commands/
```

Then:

```bash
ls -la /var/log/user_commands/users/
```

Check the current user's log:

```bash
cat /var/log/user_commands/users/$(whoami)_commands.log
```

Check whether command entries exist:

```bash
grep -c "^\[CMD\]" \
    /var/log/user_commands/users/$(whoami)_commands.log
```

---

## Permission Denied

Check:

```bash
ls -ld /var/log/user_commands
ls -ld /var/log/user_commands/users
```

Check the log files:

```bash
ls -la /var/log/user_commands/users/
```

Fix ownership/permissions according to your security policy rather than blindly using `chmod 777`.

---

## Logger Does Not Start Automatically

Check:

```bash
ls -la /etc/profile.d/user_command_logger.sh
```

Check the profile configuration:

```bash
grep -R "user_command_logger" /etc/profile /etc/profile.d/ 2>/dev/null
```

Then:

```bash
source /etc/profile
```

Start a new SSH session after making changes.

---

# 🗑️ Uninstallation

The recommended method is:

```bash
sudo /usr/m1/uninstall.sh
```

If the uninstall script is not available, remove the installed components manually.

> **Important:** Make sure you understand which logs should be retained before deleting `/var/log/user_commands/`.

After uninstalling, start a new shell session:

```bash
exit
```

Then reconnect.

---

# 🔎 Verify Uninstallation

Check:

```bash
ls -la /usr/m1/command_logger.sh
```

Check:

```bash
ls -la /etc/profile.d/user_command_logger.sh
```

Check:

```bash
ls -la /var/log/user_commands/
```

The logging functions should no longer be available in new sessions:

```bash
show_my_logs
count_my_commands
```

---

# 📋 Commands Cheat Sheet

| Command                                              | Purpose                         |
| ---------------------------------------------------- | ------------------------------- |
| `show_my_logs`                                       | Show your command history       |
| `count_my_commands`                                  | Count your commands             |
| `debug_show_raw`                                     | Show raw logging information    |
| `show_user_logs`                                     | Show all user logs              |
| `show_user_logs <user>`                              | Show a specific user's logs     |
| `/usr/m1/monitor.sh`                                 | Open admin monitoring interface |
| `tail -f /var/log/user_commands/master_commands.log` | Monitor activity in real time   |

---

# 💡 Example Workflow

### Regular User

```bash
ssh administrator@server
```

Run:

```bash
hostname
pwd
df -h
free -m
```

View activity:

```bash
show_my_logs
```

---

### Administrator

Open the monitor:

```bash
sudo /usr/m1/monitor.sh
```

Select:

```text
3. Show User Statistics
```

or:

```text
4. Show Specific User Log
```

For direct investigation:

```bash
grep "sudo" /var/log/user_commands/users/*_commands.log
```

---

# 🧩 Use Cases

Command Logger can be useful for:

### Linux Administration

Track administrative activity on shared servers.

### Security Auditing

Investigate commands executed by users.

### DevOps

Track operational activity during troubleshooting and maintenance.

### Shared Infrastructure

Monitor activity when multiple administrators access the same server.

### Training / Labs

Understand how shell sessions and command auditing work.

### Incident Investigation

Review historical command activity after a security event.

---

# ⚠️ Limitations

Command Logger is intentionally lightweight and Bash-based.

It should **not** be considered a replacement for a complete security auditing platform.

For high-security or regulated environments, consider combining command logging with:

* Linux audit framework
* Centralized logging
* SIEM
* File integrity monitoring
* SSH auditing
* Privileged Access Management
* EDR
* Wazuh or similar security platforms

Also remember that shell-based logging can have limitations depending on how commands are executed, which shell is used, and how users interact with the system.

---

# 🤝 Contributing

Contributions are welcome.

Typical contribution workflow:

```bash
git clone https://github.com/maelhabashy/command_logger.git
cd command_logger
```

Create a branch:

```bash
git checkout -b feature/my-feature
```

Make your changes, test them on a non-production Linux system, then commit:

```bash
git add .
git commit -m "Add my feature"
```

Push your branch:

```bash
git push origin feature/my-feature
```

Then open a Pull Request.

---

# 🧪 Recommended Testing

Before using changes on production servers, test:

* New user login
* Existing user login
* Root login
* SSH sessions
* Multiple concurrent users
* Commands containing spaces
* Commands containing special characters
* `sudo` usage
* `su` usage
* Shell logout
* Log rotation
* Log cleanup
* Uninstallation
* Reinstallation

---

# 📜 License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.

See [`LICENSE`](LICENSE) for the complete license text.

---

# 👨‍💻 Author

**Mohamed Elhabashy**

GitHub:

https://github.com/maelhabashy

---

# ⭐ Support the Project

If you find **Command Logger** useful:

* ⭐ Star the repository
* 🐛 Report bugs
* 💡 Suggest improvements
* 🔧 Submit Pull Requests
* 📢 Share the project with other Linux administrators

---

## 🔗 Repository

https://github.com/maelhabashy/command_logger

---

> **Command Logger — Simple Linux command auditing without the complexity of a full SIEM.**

<div>

# Configuration Files Documentation

Since this script is a lightweight backup system designed for OpenWrt,
both files use a simple **key-value syntax** based on YAML patterns,
parsed efficiently via *sed* and *awk* in POSIX shell.

## General Syntax Rules

To ensure the script parses your configuration files correctly, follow
these rules:

1.  **Simple Variables (Single-line):** *key: value* (separated by a
    colon). Any spaces after the colon are ignored.
2.  **Lists (Multi-line):** Begin with the key name followed by a colon.
    Subsequent lines contain the list values (indented with spaces or
    tabs). The list ends as soon as a new key (a line containing a
    colon) is encountered.
3.  **Comments:** Lines starting with *\#* are ignored. Inline comments
    starting with *\#* are allowed only inside expiration rules
    (*expire*).
4.  **No Special Characters in Keys:** Keys must only contain letters,
    numbers, hyphens (*-*), and underscores (*\_*).

## 1. */etc/busyback/master.conf* (Global Configuration)

This file controls global default values, defines the central backup
storage, and specifies which vaults (backup jobs) are executed by
default.

### Example Configuration

YAML

*bank: /mnt/backup_disk/busyback*

*port: 22*

*exclude:*

* /proc*

* /sys*

* /dev*

* /tmp*

* /run*

* lost+found*

*expire:*

* \# Min Hr Day Mon Wday Duration*

* \* \* \* \* \* +14 days*

* \* \* 1 \* \* +2 months*

* \* \* \* \* 1 +4 weeks*

*rsync-options:*

* --bwlimit=5000*

* --exclude-from=/etc/busyback/global_excludes.txt*

*runall:*

* system_router*

* homeserver_etc*

* nas_pictures*

### Parameter Details

|                     |                      |                                                                                                                                                    |
|---------------------|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| ***bank***          | Single-line (Path)   | **Required.** The absolute path to your central backup storage (e.g., a mounted external USB drive). Individual vault directories are stored here. |
| ***port***          | Single-line (Number) | Default SSH port for remote backups (Defaults to *22* if not overridden by the vault's config).                                                    |
| ***exclude***       | Multi-line List      | Global list of files or directories to skip. These filters are automatically passed to *rsync* for **all** backup jobs.                            |
| ***expire***        | Multi-line List      | Global retention rules in cron-like format (see details below) determining how long backups are kept.                                              |
| ***rsync-options*** | Multi-line List      | Additional global arguments passed directly to the *rsync* command (e.g., bandwidth limiting *--bwlimit*).                                         |
| ***runall***        | Multi-line List      | Defines the default execution order of your vaults. If you run the script without parameters, it processes this list sequentially.                 |

## 2. *\<bank\>/\<vault_name\>/manage/busyback.conf* (Vault Configuration)

Every backup job (vault) must have its own directory inside the *bank*
containing this local configuration file. It configures client-specific
connection info and can override or extend global settings.

### Example Configuration

YAML

*client: 192.168.1.10*

*user: root*

*port: 2222*

*wol-mac: 00:11:22:33:44:55*

*wol-net: 192.168.1.255*

*tree: /etc*

*exclude:*

* /etc/dropbear/id_dropbear_backup*

* /etc/config/luci*

*expire:*

* \* \* \* \* \* +7 days*

* \* \* \* \* 7 +4 weeks*

*rsync-options:*

* --sparse*

### Parameter Details 

Thje only required parameter is **tree**, all other parameters are
optional.

|                     |                       |                                                                                                                                             |
|---------------------|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| ***client***        | Single-line (IP/Host) | IP or hostname of the remote machine. If left blank or set to *localhost*, the script performs a local backup of the OpenWrt router itself. |
| ***user***          | Single-line (String)  | SSH username used to log into the remote client (Defaults to *root*).                                                                       |
| ***port***          | Single-line (Number)  | Overrides the global SSH port specifically for this client, defaultes to 22.                                                                |
| ***wol-mac***       | Single-line (MAC)     | The MAC address of the client. If the target is offline, the script sends a Wake-on-LAN Magic Packet to boot it.                            |
| ***wol-net***       | Single-line (IP)      | The broadcast IP of your subnet (e.g., *192.168.1.255*) to route the WoL packet. **Must be defined if *****wol-mac***** is used.**          |
| ***tree***          | Single-line (Path)    | **Required.** The source directory on the client (or local system) that should be backed up (e.g., */etc* or */home/user*).                 |
| ***exclude***       | Multi-line List       | Local files/folders to skip for this vault. These are *appended* to the global excludes.                                                    |
| ***expire***        | Multi-line List       | Fully overrides the global *expire* rules for this specific vault.                                                                          |
| ***rsync-options*** | Multi-line List       | Local *rsync* arguments for this vault. These are *appended* to the global options.                                                         |

## How the *expire* Rules Work (Dirvish-Style)

The script evaluates backup retention based on Dirvish rules. Every line
represents a distinct matching condition:

Plaintext

*Minute Hour Day Month Day-of-Week Retention Duration*

* \* \* \* \* \* +14 days*

- **Time Fields (*****\****** or specific numbers):**

  - *Day*: Day of the month (1–31)
  - *Month*: Month of the year (1–12)
  - *Day-of-Week*: Day of the week (1 = Monday, 7 = Sunday. Ranges like
    *1-5* or lists like *1,3,5* are supported).
  - *Note:* The *Minute* and *Hour* fields are ignored by the script (as
    backups usually trigger via daily cron), but they must remain in the
    file as placeholders (*\**).

- Retention Duration:

  - Defines how long a backup created on a matching day is preserved.
  - Syntax: *+X days*, *+X weeks*, *+X months*, *+X years*, or *never*
    (keep indefinitely).

### Rule Resolution Order:

When cleaning up, the script checks each backup folder's timestamp. It
runs through the *expire* rules **from top to bottom**. The **first**
rule that matches the backup’s creation date is applied. If none of the
rules match, the script defaults to a fallback retention of **14 days**.

</div>

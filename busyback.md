# Busyback

# OpenWRT incremented snapshot backup

Busyback creates a snapshot view of the filesystems to be backed up by
combining a previous backup with recent changes. It runs in OpenWRT
busybox and its processing relies on standard tool that come with the OS
of the OpenWRT router (plus little standard extentitions). It is a lean
and small tool, this documentation is the largest file in the
repository, alltgether ist about 150 kB. Busyback is not needed to
access backuped data.

For convenience the system storing the backup (e.g. the OpenWRT router
or other systems that run busybox) is called the „backup server“. In
contrast, the server/system, that is subject to the backup, is named the
„backup client“

**Separation of Concerns (Encryption):** busyback does not include
encryption. Encryption is to be handled at the OS/storage layer (e.g.,
via LUKS dm-crypt containers). The backup script remains agnostic to the
underlying crypto layout, operating solely on the unlocked, mounted
filesystem block device.

**Core Engine (Rsync):** Busyback orchestrates the target layout by
utilizing native *rsync* for differentials. It relies heavily on
standard filesystems supporting hard links to create space-efficient,
point-in-time snapshot trees.

Busyback has a dry run feature as default. To execute backups add „go“
as last command line paramter, else it is a dry run and does not change
anything on disk.

## Introduction & Concept

When triggered al vaults in the master.conf file are processed. To
process a single vault, give the vault as command line parameter. The
following steps are executed, step 1 nd 2 once per run, from step 3 on
for every vault processed:

### 1) Load Global Configuration

Parses the primary master configuration file (*master.conf*) to
establish default base fields such as the storage *bank*, default
exclusion lists, and the global fallback SSH port.

### 2) Check Precondition

Checks mounted crypto drive and existence of needed folder.

### Thje following steps loop through all Vaults:

### 3) Load Local Vault Settings

Reads the vault (client) specific configuration file (*busyback.conf*)
for config params that override global parameters (*exclude*,
*rsync-options*, local overrides for retention rules, or a customized
target port).

### 4) Assemble Rsync options

Compile Standard options and excludes from global and local conf file,
set authentication for clien.

### 5) Resolve Network Identity

Local bakups are just defined by the root of the tree to backup. If no
host is set or „localhost“, localhost will be the backup client.
Identifies the remote targets user, cleint hostname or IP address plus
an optional port and checks availability. Fallback for user, client and
port are root, localhost, 22. A client-specific port definition takes
absolute precedence over a global port config. Authorisation for remote
clients is implemented by setting *\$RSYNC_RSH* to the internal key. The
key mst be in th users „authorized keys“ on client side, preferable with
„forced command“ see wrapper script below. In addition the client mustt
be in tehknpown hoste file of the backu server’s root. An initial
reachability check by SSH handshake (ssh \<user\>@\<client\> -p \<port\>
„exit“) within a defined timeout window.). If the client fails to
respond and both MAC address and net segment of the client are defined
in the config, the script issues a broadcast magic packet to wake up the
remote station. Then pauses execution for a 45-second sleep interval to
allow the remote system (such as a Windows desktop resuming from sleep)
to initialize its networking stack, followed by a final SSH handshake
re-check. If the client is still not reachable, the vault is skipped.

### 6) Expiry

According to global or local expiry rule in cron like fomat obsolete
backups are removed.

### 7) Find Best Reference Image for Hardlinks

Parses the vault index backward to find the most recent *successful*
(non-failed) backup image. This chosen backup is passed to the engine as
the *--reference* image, ensuring that unchanged files simply generate
standard filesystem hardlinks instead of transferring duplicate data
over the network.

### 8) Clean and Preserve Broken Backups

Audits the target vault's history to handle incomplete or interrupted
runs (e.g., from a previous network drop or power failure). It checks
for unfinalized snapshot directories. if no successful backup as
reference was found in step 8, the youngest „incomplete“ unsuccessful
backup is stored as a fallback referecne backup, this backup is choosen
with the rsync option –compare-dest (instead of –link-dest) as a
reference for the current backup. Instead of deleting corrupted data, it
renames and isolates the broken directory with a *.incomplete* suffix,
clearing the workspace without data loss.

### 9) Execute Backup

Injects the custom port and SSH keys via the *\$RSYNC_RSH* environment
variable and starts the backup run for thei vault with the so far
derived options/parameters. System output and transfer statistics are
streamed into a *log* file. Upon a successful zero-exit code completion,
the script generates a *summary* file to mark the new snapshot as a
valid reference point for future runs.

## Preconditions & Setup

### Prerequisites

Before executing the script, ensure the following tools are installed:

- *rsync*
- *socat (only if WOL needed)*

### SSH Key Distribution

To automate backups securely, setup passwordless authentication using
the local user footprint.

1.  **Authorized Keys:** Append the backup server's public key (e.g.,
    */etc/dropbear/id_dropbear_backup.pub* or *id_rsa.pub*) to the
    target remote user's (i.e. root or admin user on Windows with cygwin
    ) *authorized_keys* file.

2.  **Known Hosts:** Add backup clients host key to the known hosts file
    of backup server’s root, best by once calling „ssh
    \<user\>@\<client\> -p \<port\>“ from command line and answering
    „yes“ – the host key is added, even if there is no loigin after that
    .

3.  **Forced Command Wrapper on clients:** busyback may need to run with
    root rights, e.g. to backup a system folder or a set of folders
    belonging to several users. To prevent rogue root commands, use the
    forced command directive and prefix the target *authorized_keys*
    entry with restricted execution blocks if required by security
    policies:

    *command="/root/.ssh/allowed_commands.sh 2\>
    /root/.ssh/allowed_commands\_\`/bin/date
    +\\Y-\\m-\\d\_\\H-\\M-\\S\`\_stderr.log",no-port-forwarding,no-X11-forwarding,no-agent-forwarding
    ssh-ed25519 AAA….. *

    **in the script „allowed_commands.sh“ allow commands like**

    *rsync\\ --server\\ --sender\\
    -\*(\[vnklLH\])ogD?(t)p?(A)?(X)r?(x)?(x)e.iLfxCIvu\\
    ?(--ignore-errors\\ )?(--safe-links\\ )?(--numeric-ids\\ ).\\
    \\@(etc\|home)\\*

    **and all other commands wh**i**ch are allowed. **The script also
    uses **the **commad „exit“, an**d** in the script there are twe more
    commnads („ls /etc“ and „cat /etc/hosts“) allowed for testing
    purposes.**

    **and all other commands wh**i**ch are allowed. **The script also
    uses **the **commad „exit“, an**d** in the script there are twe more
    commnads („ls /etc“ and „cat /etc/hosts“) allowed for testing
    purposes.**

### Setup

**Create a mount point „/mnt/OpenWRT_vaults/“ busyback on the backup
server. In what follows, all references to the name. You may choose a
different one, but be aware of changes when reading further, in
particular in the conjobs. Be aware that in the cryptsetup config files
character of device names are limited. e.g „\_“ is allowed, but „-“
not.**

**

**Mount and unlock your backup device. Busyback runs without that, but
if you do not have a device, the backup ist stored in the disk space of
the backup server, which space may be limitid. If you do not have an
encrypted devi**c**e, your backups will be plain. For testing puposes
you can skip mount and unlock. To easy create and unlock a device under
busybo**x** see repo „crypto-manage“ in GitHub.**

**

**Copy the whole structure of the repo into
„/mnt/OpenWRT_vaults/manage“**

#### ****Main****** files:****

**core (chmod to executeable)**

**/mnt/OpenWRT_vaults/global_manage/cdbin/busyback to
/usr/bin/busyback**

**

**what are the latest successful backups (chmod to executeable)**

**/mnt/OpenWRT_vaults/global_manage/bin/latest_busyback to
/usr/bin/latest_busyback**

**

**Global defaults**

**/mnt/OpenWRT_vaults/global_manage/master.conf to
/etc/busyback/master.conf**

**

**Roots crontab - create or add**

**roots_crontab.crtb**

#### *Other files:*

**cronjobs stay in OpenWRT_vaults/global_manage**

**busyback_cronjob.sh - core cronjob**

**hourly_cronjob.sh - backup of the config and bin files to a save
place**

**

**The configuration file defining client overrides, create one for each
backup **

**(see examples and more info below)**

**/mnt/OpenWRT_vaults/busyback-bank\>/\<vault\>/manage/busyback.conf**

**

**On Clients: Wrapper script in root’s .ssh(See below)**

**allowed_commands.sh**

# Windows Integration Bridge

Backing up Windows systems requires handling locked runtime database
states and modern power-saving behavior.

### Windows Wake-On-LAN (WoL)

Because Windows clients frequently sleep or hibernate when idle, the
configuration must explicitly declare the target physical MAC address
and net segment inside *busyback.conf* to guarantee the device is
powered up prior to rsync initialization.

### VSS-Backed Rsync Engine

Windows locks system files and active user profiles (e.g., Outlook
*.pst* files, database files) during normal operation. Standard rsync
binaries will fail to read these files. To bypass this, the Windows
target must execute an rsync client that is fully integrated with the
native **Volume Shadow Copy Service (VSS)**.

- **Client Path:** The target binary path used on Windows systems is:
  *'c:/Program Files/True_Blade_Systems/tb-rsync-vss-64.exe'*
- **Rsync Options:** The configuration must include flags matching the
  technical capabilities of the VSS engine, prioritizing path
  translation formatting compatible with shadow volumes (e.g.,
  */cygdrive/c/* syntax mappings).

# Use Cases

- **Heterogeneous Server Environments:** Backing up Linux headless
  infrastructure alongside Windows desktop environments using unified
  syntax rules.
- **Non-Standard SSH Port Topologies:** Securing external edge
  environments behind dynamic NAT mappings where clients expose
  customized incoming ports instead of port *22*.
- **Green-IT Powered Desktop Nodes:** Powering up targeted office
  workstations on demand in the middle of the night via WoL, pulling a
  full daily differential snapshot, and letting them return to sleep
  states safely.

# Operational Runbook (Post-Reboot Procedures)

Whenever the backup (OpenWRT) host or hypervisor experiences a system
reboot, tasks must be run manually or orchestrated via global management
wrappers to return to a baseline backup-ready state.

### 1. Storage & Cryptography Layer Validation

Open your underlying encrypted block array manually to make the file
path accessible to the backup process again:

Bash

*\# Example open routine (adjust names to your specific environment)*

*crypto-manage open backup_storage go *

### 

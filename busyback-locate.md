# busyback-locate

*busyback-locate* is a high-performance CLI tool for OpenWrt. It searches through historical busyback backup snapshots for specific files or directories and displays **only real changes** (unique versions). Unchanged backups that were linked via hard links (*rsync --link-dest*) are automatically filtered out to save time and cognitive load.

## How It Works

To minimize CPU load on your router and reduce disk thrashing on your backup drive, the tool uses a fast, compressed **index-based approach**:

1.  **Index Generation & Compression (During Backup): **After every successful backup run, the main script creates a flat metadata list of every single backed-up item (storing inode, size, type, and relative path). This list is immediately compressed using *gzip* and saved as *index.gz* inside the snapshot directory, drastically reducing the storage footprint on the backup medium.

2.  Smart Data Filtering (During Search):

    - **Stream Decompression:** When searching, *busyback-locate* streams the contents of *index.gz* directly into memory using *zcat*, ensuring lightning-fast text searches without extracting files to the disk.
    - **Files & Symlinks: **The tool checks the physical inode number on the filesystem. If the inode in a newer snapshot matches one from a previous snapshot, it is identified as a hard link (no data changed) and skipped.
    - **Directories:** Because Linux filesystems do not allow hard-linking directories, *busyback-locate* tracks them using a unique fingerprint based on their path and directory size (which only changes under Linux when files inside that specific directory are added or deleted).

## Usage

The tool requires two arguments: the name of the **vault** (backup target directory) and a **search pattern** (filename, partial name, or path fragment).

### Syntax

Bash

*busyback-locate \<vault_name\> \<search_pattern\>*

### Examples

#### 1. Searching for a specific configuration file

Plaintext

*\# busyback-locate system_router wireless*

*Searching index for: 'wireless'*

*Vault: system_router*

*----------------------------------------------------------------------*

*Backup-Snapshot \| Size/KB \| Type \| Relative Path*

*----------------------------------------------------------------------*

*2026-07-01-0200 \| 2 \| file \| etc/config/wireless*

*2026-07-12-0200 \| 3 \| file \| etc/config/wireless*

*What this means:* Even if your backup runs daily, the *wireless* config only actually changed on July 1st and July 12th. All other days are omitted because they were identical hard links containing no new data.

#### 2. Tracking changes on a directory level

Plaintext

*\# busyback-locate system_router etc/config*

*Searching index for: 'etc/config'*

*Vault: system_router*

*----------------------------------------------------------------------*

*Backup-Snapshot \| Size/KB \| Type \| Relative Path*

*----------------------------------------------------------------------*

*2026-07-01-0200 \| 4096 \| directory \| etc/config*

*What this means:* The directory *etc/config* was indexed on July 1st. Since no files were added or removed from this specific directory since then, it does not reappear in later snapshots, keeping your history completely clean.

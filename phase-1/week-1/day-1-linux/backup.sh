#!/usr/bin/env bash
set -euo pipefail

# =====================================================================
# Script: backup.sh
# Description: Backup a directory as a .tar.gz archive in ~/backups/
# =====================================================================

# Function to show help and usage instructions
show_help() {
    echo "Usage: $(basename "$0") <directory_to_backup>"
    echo "Backup a directory as a .tar.gz archive stored in ~/backups/"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
}

# Function to perform the backup and print statistics
perform_backup() {
    local target_dir="$1"
    
    # Check if the target directory exists
    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' does not exist." >&2
        exit 1
    fi

    # Resolve absolute path to prevent naming the backup '.' when '.' is passed
    local target_abs_path
    target_abs_path=$(realpath "$target_dir")

    # Ensure backup directory exists
    local backup_dir="$HOME/backups"
    mkdir -p "$backup_dir"

    # Get directory name and timestamp
    local dir_basename
    dir_basename=$(basename "$target_abs_path")
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)

    local backup_file="${dir_basename}-${timestamp}.tar.gz"
    local backup_path="${backup_dir}/${backup_file}"

    echo "Backing up directory '$target_abs_path'..."

    # Compress the source directory from its parent folder
    tar -czf "$backup_path" -C "$(dirname "$target_abs_path")" "$dir_basename"

    # Calculate count of files and size of the generated archive
    # Use grep -v '/$' to exclude directories from the file count
    local file_count
    file_count=$(tar -tzf "$backup_path" | grep -v '/$' | wc -l)

    local backup_size
    backup_size=$(du -sh "$backup_path" | cut -f1)

    echo "----------------------------------------"
    echo "Backup completed successfully!"
    echo "Archive path: $backup_path"
    echo "Files backed up: $file_count"
    echo "Backup size: $backup_size"
    echo "----------------------------------------"
}

# --- Command Line Arguments Parsing ---

# If no arguments provided, show help and exit with 1
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        # Remove trailing slash if present
        input_dir="${1%/}"
        perform_backup "$input_dir"
        ;;
esac

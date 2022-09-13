#!/bin/sh


# Quickstart: modify the variables in all caps.
# For the first 3 make sure the folders exist and there is a slash at the end.

SOURCE_PATH="/home/username/"
BACKUP_PATH="/mnt/yourFavBackupLocation/"
ARCHIVE_PATH="/mnt/yourFavBackupLocation/archive/"
DB_PATH="/mnt/yourFavBackupLocation/backupdb.json"
DAYS_AFTER_DELETE=10

timespamp_now=$(date +%s)
timestamp_in_x_days=$(date -d "+$DAYS_AFTER_DELETE days" +%s)

# This is used for logging. You can see
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$BACKUP_PATH/backup.log 2>&1

echo "-----Starting run on $(date)-----"
echo ""

# Check for dependencies
dependencies=("jq" "rsync")
for dependency in "${dependencies[@]}"; do
    if ! command -v "$dependency" &> /dev/null; then
        echo "$dependency not installed!"

        echo ""
        echo "-----Run finished at $(date)-----"
        echo ""
        echo "===================================================================="
        echo ""

        exit 0
    fi
done

# Do the backup normally, let rsync handle everything
# You can modify this command to your liking
# (make sure you keep -r and -R otherwise it might break stuff. -v is recommended for logging)

rsync -rRtv --exclude '.cache' "$SOURCE_PATH" "$BACKUP_PATH"


# If the db doesn't exist, make a template json and exit

if [ ! -f $DB_PATH ]; then
    echo "{\"pending_deletion\": []}" > "$DB_PATH"

    echo ""
    echo "-----Run finished at $(date)-----"
    echo ""
    echo "===================================================================="
    echo ""

    exit 0
fi


# Read db and determine which files/folders should be deleted according to their delete time
# then delete them and remove the db entry

deletepaths=()
readarray -t deletepaths < <(jq -r '.pending_deletion[].path' "$DB_PATH")

for deletepath in "${deletepaths[@]}"; do
    timestamp=$(jq -r '[.pending_deletion[] | select(.path == "'"$deletepath"'").delete_on][0]' "$DB_PATH")
    if [[ $timespamp_now -ge $timestamp ]]; then
        if [[ -f $deletepath || -d $deletepath ]]; then
            echo "Deleting $deletepath from the archive..."
            rm -rf "$deletepath"
        fi
        jq 'del(.pending_deletion[] | select(.path == "'"$deletepath"'"))' "$DB_PATH" > "$DB_PATH.tmp" && mv "$DB_PATH.tmp" "$DB_PATH"
    fi
done


# Delete empty folder from the archive
# Sometimes folders are left over from deleted files. Who need empty folders?

if [[ -d $ARCHIVE_PATH ]]; then
    find "$ARCHIVE_PATH" -type d -empty -delete
fi


# Get list of files/folders that rsync thinks should be deleted
# then move them on the archive and mark them for deletion on today + x days
#
# We sort the path list alphabetically so if a whole folder was deleted, it first procceses the parent folder and then the
# other files (which get skipped because they have been moved to the archive and don't exist anymore).
# This saves time and db entries :)

paths=()
readarray -t paths < <(rsync -rRvn --exclude '.cache' --delete "$SOURCE_PATH" "$BACKUP_PATH" | grep deleting | sed "s|deleting ||g" | sort)

for path in "${paths[@]}"; do
    echo "$BACKUP_PATH$path marked for deletion"
    if [[ -f $BACKUP_PATH$path || -d $BACKUP_PATH$path ]]; then
        echo "Moving $BACKUP_PATH$path to archive..."
        mkdir --parents "$(dirname "$ARCHIVE_PATH$path")"
        if [[ -d $BACKUP_PATH$path ]]; then # folder
            cp -aft "$BACKUP_PATH$path"* "$(dirname "$ARCHIVE_PATH$path")"/
        else # file
            cp -f "$BACKUP_PATH$path" "$(dirname "$ARCHIVE_PATH$path")"/
        fi
        rm -rf "$BACKUP_PATH$path"
        jq '.pending_deletion += [{"path": "'"$ARCHIVE_PATH$path"'", "delete_on": '"$timestamp_in_x_days"'}]' "$DB_PATH" > "$DB_PATH.tmp" && mv "$DB_PATH.tmp" "$DB_PATH"
    fi
done

echo ""
echo "-----Run finished at $(date)-----"
echo ""
echo "===================================================================="
echo ""

exit 0

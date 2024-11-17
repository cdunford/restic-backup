#!/bin/bash

RESTIC_REPOSITORY=$1
ROOT_DIR=$2
LOG_FILE=$3
FILES_FROM=$4
PASSWORD_FILE=$5
TIMEOUT=$6
MAIL_ADDRESS=$7

export RESTIC_REPOSITORY

echo "Backing up to $RESTIC_REPOSITORY" >"$LOG_FILE"

pushd "$ROOT_DIR" || exit

RESTIC_PASSWORD=$(gpg --quiet --for-your-eyes-only --no-tty --decrypt "$PASSWORD_FILE")
export RESTIC_PASSWORD

{
  echo "Working directory $(pwd)"
  cat "$FILES_FROM"

  ls -l

  printf "\nSTARTING BACKUP\n"
  timeout -s TERM "$TIMEOUT" restic \
    --skip-if-unchanged \
    --verbose \
    backup \
    --files-from "$FILES_FROM"

  if [ $? -eq 124 ]; then
    printf "\nBACKUP TIMEOUT\n"
  fi

  printf "\nSNAPSHOTS\n"
  restic \
    snapshots

  printf "\nFILES IN LATEST SNAPSHOT\n"
  restic \
    ls \
    --recursive \
    latest

} >>"$LOG_FILE" 2>&1

mail -s "Backup Log for $(hostname) - $(date)" "$MAIL_ADDRESS" <"$LOG_FILE"

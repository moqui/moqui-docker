#!/bin/bash

# Set Moqui setup directory
MOQUI_SETUP_DIR="/opt/moqui"

# Check if $MOQUI_SETUP_DIR exists; if not, clone the repository
if [ ! -d "$MOQUI_SETUP_DIR" ]; then
  # Are you sure you want to delete this and all the backups?
  read -p "Directory $MOQUI_SETUP_DIR already exists. Are you sure you want to delete this and all backups? (y/n): " confirm
  if [ "$confirm" = "y" ]; then
    echo "Deleting $MOQUI_SETUP_DIR and all backups..."
    rm -rf "$MOQUI_SETUP_DIR"
  fi

fi

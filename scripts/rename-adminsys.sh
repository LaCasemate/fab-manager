#!/usr/bin/env bash

config()
{
  echo -ne "Checking env file... "
  FABMANAGER_PATH=$(pwd)
  if [ ! -w "$FABMANAGER_PATH/config/env" ]; then
    echo "Fab-manager's environment file not found or not writable."
    echo "Please run this script from the installation folder, and as a user having write access on config/env"
    exit 1
  fi
}

rename_var()
{
  current=$(grep "SUPERADMIN_EMAIL=" "$FABMANAGER_PATH/config/env")
  sed -i.bak "s/SUPERADMIN_EMAIL=$current/ADMINSYS_EMAIL=$current/g" "$FABMANAGER_PATH/config/env"
}

proceed()
{
  config
  rename_var
}

proceed "$@"

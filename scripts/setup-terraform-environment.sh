#!/usr/bin/env bash

# To use: run source ./setup-terraform-environment.sh

if ! op whoami >/dev/null 2>&1; then
  echo "1Password session not found."
  echo "   Initiating sign-in..."
  
  eval $(op signin)
  
  if [ $? -ne 0 ]; then
    echo "Sign-in failed or was cancelled. Exiting."
    return 1
  fi
  
  echo "Sign-in successful."
else
  echo "Already signed in to 1Password."
fi

# B2 API Access
export AWS_ACCESS_KEY_ID=$(op read "op://Private/Backblaze B2 Bucket Key/keyID")
export AWS_SECRET_ACCESS_KEY=$(op read "op://Private/Backblaze B2 Bucket Key/credential")

# Proxmox API Access
export PROXMOX_VE_API_TOKEN="$(op read "op://Private/Proxmox API and terraform user/PROXMOX_VE_API_TOKEN")"
export PROXMOX_VE_SSH_USERNAME="$(op read "op://Private/terraform user ssh key/username")"
export PROXMOX_VE_SSH_PRIVATE_KEY="$(op read "op://Private/terraform user ssh key/private key")"
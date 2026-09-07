echo "Start 1Password at a fixed scale factor from the app menu too"

# The hotkey has always gone through omarchy-launch-1password, but the packaged
# .desktop ran the binary straight, so launching from the app menu skipped the
# scale pin. Install the override for anyone who already has 1Password.
if omarchy-cmd-present 1password; then
  mkdir -p "$HOME/.local/share/applications"
  install -m 644 "$OMARCHY_PATH/default/applications/1password.desktop" \
    "$HOME/.local/share/applications/1password.desktop"
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

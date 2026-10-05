#!/bin/sh
set -eu

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
config_dir="$config_home/quickshell/archwave-winamp"
launcher="$HOME/.local/bin/archwave-winamp"

rm -f "$config_dir/shell.qml" "$launcher"
rmdir "$config_dir" 2>/dev/null || true

printf '%s\n' 'Removed the Archwave QuickShell Player config and launcher.'
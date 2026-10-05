#!/bin/sh
set -eu

if ! command -v quickshell >/dev/null 2>&1; then
    printf '%s\n' "Error: QuickShell is required. Install it, then run this script again." >&2
    exit 1
fi

source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
config_dir="$config_home/quickshell/archwave-winamp"
bin_dir="$HOME/.local/bin"
launcher="$bin_dir/archwave-winamp"

mkdir -p "$config_dir" "$bin_dir"
install -m 644 "$source_dir/WinampWidget.qml" "$config_dir/shell.qml"

cat > "$launcher" <<EOF
#!/bin/sh
exec quickshell --path "$config_dir/shell.qml" "\$@"
EOF
chmod 755 "$launcher"

printf 'Installed config: %s\n' "$config_dir/shell.qml"
printf 'Launcher: %s\n' "$launcher"
if ! command -v pactl >/dev/null 2>&1; then
    printf '%s\n' 'Warning: pactl was not found; the volume and balance sliders will not work.' >&2
fi
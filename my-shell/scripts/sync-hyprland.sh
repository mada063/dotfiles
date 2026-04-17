#!/usr/bin/env bash
set -euo pipefail

settings_path="${1:?missing settings path}"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
managed_path="$config_dir/quickshell-generated.conf"
main_path="$config_dir/hyprland.conf"

mkdir -p "$config_dir"

python3 - "$settings_path" "$managed_path" <<'PY'
import json
import os
import sys

settings_path = sys.argv[1]
managed_path = sys.argv[2]

with open(settings_path, "r", encoding="utf-8") as fh:
    cfg = json.load(fh)

def rgba(value, fallback):
    text = str(value or fallback).strip().lower()
    if not text.startswith("#"):
        text = fallback
    text = text.lstrip("#")
    if len(text) == 6:
        text = text + "ff"
    if len(text) != 8:
        text = fallback.lstrip("#") + "ff"
    return f"rgba({text})"

managed_enabled = bool(cfg.get("hyprlandManagedEnabled", True))
decoration = cfg.get("hyprlandDecoration") or {}
monitors = cfg.get("hyprlandMonitors") or []
binds = cfg.get("hyprlandBinds") or []
workspace_rules = cfg.get("hyprlandWorkspaceRules") or []

MODIFIER_MAP = {
    "CTRL": "CTRL",
    "ALT": "ALT",
    "SHIFT": "SHIFT",
    "META": "SUPER",
    "SUPER": "SUPER",
}

KEY_MAP = {
    "RETURN": "RETURN",
    "ENTER": "RETURN",
    "SPACE": "SPACE",
    "TAB": "TAB",
    "BACKTAB": "TAB",
    "BACKSPACE": "BACKSPACE",
    "DELETE": "DELETE",
    "INSERT": "INSERT",
    "ESC": "ESCAPE",
    "ESCAPE": "ESCAPE",
    "HOME": "HOME",
    "END": "END",
    "PGUP": "PAGEUP",
    "PAGEDOWN": "PAGEDOWN",
    "PGDN": "PAGEDOWN",
    "LEFT": "LEFT",
    "RIGHT": "RIGHT",
    "UP": "UP",
    "DOWN": "DOWN",
    "PLUS": "PLUS",
    "MINUS": "MINUS",
    "EQUAL": "EQUAL",
    "COMMA": "COMMA",
    "PERIOD": "PERIOD",
    "SLASH": "SLASH",
    "BACKSLASH": "BACKSLASH",
    "SEMICOLON": "SEMICOLON",
    "APOSTROPHE": "APOSTROPHE",
    "BRACKETLEFT": "BRACKETLEFT",
    "BRACKETRIGHT": "BRACKETRIGHT",
    "QUOTELEFT": "GRAVE",
}

def parse_shell_sequence(value):
    parts = [part.strip() for part in str(value or "").split("+") if part.strip()]
    if not parts:
        return None
    raw_key = parts[-1].upper()
    key = KEY_MAP.get(raw_key, raw_key if len(raw_key) != 1 else raw_key.upper())
    modifiers = []
    for raw_modifier in parts[:-1]:
        mapped = MODIFIER_MAP.get(raw_modifier.strip().upper())
        if mapped and mapped not in modifiers:
            modifiers.append(mapped)
    return " ".join(modifiers), key

def shell_global_binds(settings):
    shortcuts = [
        ("controlCenterEnableHotkey", "controlCenterHotkey", "control-center"),
        ("dashboardEnableHotkey", "dashboardHotkey", "dashboard"),
        ("sidebarEnableHotkey", "sidebarHotkey", "quick-sidebar"),
    ]
    lines = []
    for enabled_key, sequence_key, name in shortcuts:
        if not settings.get(enabled_key, False):
            continue
        parsed = parse_shell_sequence(settings.get(sequence_key, ""))
        if not parsed:
            continue
        modifiers, key = parsed
        lines.append(f"bind = {modifiers}, {key}, global, quickshell:{name}")
    return lines

lines = ["# Managed by Quickshell.", "# Manual edits may be overwritten.", ""]

if not managed_enabled:
    lines.append("# Hyprland integration disabled from Quickshell settings.")
else:
    active_border = rgba(decoration.get("activeBorderColor"), "#ff8c32")
    inactive_border = rgba(decoration.get("inactiveBorderColor"), "#444444")

    lines += [
        "general {",
        f"    gaps_in = {int(decoration.get('gapsIn', 5))}",
        f"    gaps_out = {int(decoration.get('gapsOut', 10))}",
        f"    border_size = {int(decoration.get('borderSize', 2))}",
        f"    col.active_border = {active_border}",
        f"    col.inactive_border = {inactive_border}",
        "}",
        "",
        "decoration {",
        f"    rounding = {int(decoration.get('rounding', 8))}",
        "    blur {",
        f"        enabled = {'true' if decoration.get('blurEnabled', True) else 'false'}",
        f"        size = {int(decoration.get('blurSize', 8))}",
        f"        passes = {int(decoration.get('blurPasses', 1))}",
        "    }",
        "}",
        ""
    ]

    for monitor in monitors:
        name = str(monitor.get("name", "")).strip()
        if not name:
            continue
        if not monitor.get("enabled", True):
            lines.append(f"monitor = {name}, disable")
            continue
        mode = str(monitor.get("mode", "preferred")).strip() or "preferred"
        position = f"{int(monitor.get('positionX', 0))}x{int(monitor.get('positionY', 0))}"
        scale = monitor.get("scale", 1)
        monitor_line = f"monitor = {name}, {mode}, {position}, {scale}"
        mirror_of = str(monitor.get("mirrorOf", "")).strip()
        if mirror_of:
            monitor_line += f", mirror, {mirror_of}"
        transform = int(monitor.get("transform", 0))
        if transform:
            monitor_line += f", transform, {transform}"
        lines.append(monitor_line)

    if monitors:
        lines.append("")

    generated_shell_binds = shell_global_binds(cfg)
    if generated_shell_binds:
        lines.append("# Quickshell global shortcuts")
        lines.extend(generated_shell_binds)
        lines.append("")

    for bind in binds:
        mods = str(bind.get("mods", "")).strip()
        key = str(bind.get("key", "")).strip()
        dispatcher = str(bind.get("dispatcher", "")).strip()
        argument = str(bind.get("argument", "")).strip()
        if not key or not dispatcher:
            continue
        lines.append(f"bind = {mods}, {key}, {dispatcher}, {argument}")

    if binds:
        lines.append("")

    for rule in workspace_rules:
        workspace = str(rule.get("workspace", "")).strip()
        if not workspace:
            continue
        parts = []
        monitor = str(rule.get("monitor", "")).strip()
        default_name = str(rule.get("defaultName", "")).strip()
        if monitor:
            parts.append(f"monitor:{monitor}")
        if default_name:
            parts.append(f"name:{default_name}")
        if rule.get("persistent", False):
            parts.append("persistent:true")
        if rule.get("isDefault", False):
            parts.append("default:true")
        suffix = ", ".join(parts)
        lines.append(f"workspace = {workspace}" + (f", {suffix}" if suffix else ""))

content = "\n".join(lines).rstrip() + "\n"
with open(managed_path, "w", encoding="utf-8") as fh:
    fh.write(content)
PY

include_line='source = ~/.config/hypr/quickshell-generated.conf'

if [ -f "$main_path" ]; then
    if ! rg -Fq "$include_line" "$main_path"; then
        printf '\n%s\n' "$include_line" >> "$main_path"
    fi
fi

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

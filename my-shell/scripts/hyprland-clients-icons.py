#!/usr/bin/env python3
"""
Augment hyprctl clients JSON with iconPath per client (Freedeesktop StartupWMClass + icon theme lookup).
Stdout: Hyprland's client list JSON with iconPath strings (empty if unresolved).
"""

from __future__ import annotations

import glob
import json
import os
import re
import subprocess
import sys


def hypr_clients_json() -> list:
    try:
        r = subprocess.run(
            ["hyprctl", "clients", "-j"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        if r.returncode != 0:
            return []
        raw = (r.stdout or "").strip()
        if not raw:
            return []
        data = json.loads(raw)
        return data if isinstance(data, list) else []
    except (OSError, json.JSONDecodeError, subprocess.TimeoutExpired):
        return []


_theme_icon_cache: dict[str, str] = {}


def resolve_theme_icon(icon_name: str) -> str:
    """Freedeesktop icon name -> existing file path, or ''."""
    if not icon_name or icon_name == "-" or icon_name.startswith("."):
        return ""

    stem = icon_name.strip().strip('"')
    if stem.startswith(("~", "/")):
        p = os.path.expanduser(stem)
        return p if os.path.isfile(p) else ""

    name = os.path.basename(stem)
    target = os.path.splitext(name)[0].lower()

    roots: list[str] = []
    for d in ("~/.icons", "~/.local/share/icons", "/usr/share/icons"):
        p = os.path.expanduser(d)
        if os.path.isdir(p):
            roots.append(p)

    theme = (
        os.environ.get("GTK_ICON_THEME")
        or os.environ.get("ICON_THEME")
        or "hicolor"
    )

    cache_key = f"{stem.lower()}|{theme.lower()}"
    if cache_key in _theme_icon_cache:
        return _theme_icon_cache[cache_key]

    candidates: list[str] = []
    for root in roots:
        for pat in (
            os.path.join(root, theme, "**", "apps", name + "*"),
            os.path.join(root, "hicolor", "**", "apps", name + "*"),
        ):
            for hit in glob.glob(pat, recursive=True):
                if os.path.isfile(hit):
                    candidates.append(hit)

    for hit in glob.glob(os.path.join("/usr/share/pixmaps", name + "*")):
        if os.path.isfile(hit):
            candidates.append(hit)

    def score(path: str) -> tuple:
        lp = path.lower()
        bn = os.path.splitext(os.path.basename(lp))[0]
        exact = bn == target
        return (
            -int(exact),
            -(theme.lower() in lp),
            -int(any(s in lp for s in ("48x48", "64x64", "scalable", "symbolic"))),
            -int(lp.endswith(".svg")),
            -int(lp.endswith(".png")),
            len(lp),
        )

    candidates = sorted(set(candidates), key=score)
    out = candidates[0] if candidates else ""
    _theme_icon_cache[cache_key] = out
    return out


_wmclass_icons: dict[str, str] = {}
_desktop_loaded = False


def _index_desktops() -> None:
    global _desktop_loaded
    if _desktop_loaded:
        return
    _desktop_loaded = True

    dirs = ["/usr/share/applications"]
    xd = os.path.expanduser("~/.local/share/applications")
    if os.path.isdir(xd):
        dirs.append(xd)

    wm_pat = re.compile(r"^\s*(?:Startup)?WMClass\s*=\s*(.+)$", re.I)
    icon_pat = re.compile(r"^\s*Icon\s*=\s*(.+)$", re.I)
    noc_pat = re.compile(r"^\s*NoDisplay\s*=\s*true\s*$", re.I)

    for d in dirs:
        if not os.path.isdir(d):
            continue
        for path in glob.glob(os.path.join(d, "*.desktop")):
            try:
                txt = open(path, encoding="utf-8", errors="ignore").read()
            except OSError:
                continue
            if noc_pat.search(txt):
                continue
            wm_match = wm_pat.search(txt)
            ic_match = icon_pat.search(txt)
            if not wm_match or not ic_match:
                continue
            wmcls = wm_match.group(1).strip()
            ic = ic_match.group(1).strip().split(",", 1)[0].strip().strip(";")
            if not wmcls or not ic:
                continue
            for part in re.split(r"[;\s]+", wmcls):
                k = part.strip().lower()
                if k and k not in _wmclass_icons:
                    _wmclass_icons[k] = ic


def icon_path_for_wmclass(wmcls: str) -> str:
    raw = (wmcls or "").strip()
    if not raw:
        return ""

    tokens = []
    tokens.append(raw)
    tokens.append(raw.lower())
    if "," in raw:
        for tok in raw.split(","):
            t = tok.strip()
            if t:
                tokens.append(t)
                tokens.append(t.lower())

    _index_desktops()

    specs: list[str] = []
    for t in tokens:
        k = t.lower()
        ic = _wmclass_icons.get(k)
        if ic:
            specs.append(ic)

    for spec in specs:
        p = resolve_theme_icon(spec)
        if p:
            return p

    for t in tokens:
        p = resolve_theme_icon(t)
        if p:
            return p

    return ""


def main() -> None:
    clients = hypr_clients_json()
    for c in clients:
        if not isinstance(c, dict):
            continue

        builtin = ""
        hi = c.get("iconPath") or c.get("icon") or ""
        if isinstance(hi, str):
            builtin = hi.strip()

        wm = (
            c.get("initialClass")
            or c.get("class")
            or c.get("initialTitle")
            or ""
        )

        resolved = ""
        if builtin:
            b = builtin.strip()
            if b.startswith("file://"):
                b = b[7:]
            if b.startswith(("~", "/")):
                exp = os.path.expanduser(b)
                if os.path.isfile(exp):
                    resolved = exp
            if not resolved:
                bp = resolve_theme_icon(b.strip() if b else builtin)
                if bp and os.path.isfile(bp):
                    resolved = bp
        if not resolved and isinstance(wm, str):
            resolved = icon_path_for_wmclass(wm)

        c["iconPath"] = resolved

    sys.stdout.write(json.dumps(clients, separators=(",", ":"), ensure_ascii=False))


if __name__ == "__main__":
    main()

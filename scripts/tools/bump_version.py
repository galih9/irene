#!/usr/bin/env python3
"""
Project Irene - Version & Build Number Bumper.
Synchronizes versioning across:
  - scripts/core/app_version.gd
  - project.godot
  - export_presets.cfg

Usage:
  python3 scripts/tools/bump_version.py --build          # Increment build number
  python3 scripts/tools/bump_version.py --patch          # Increment patch (e.g. 1.0.8 -> 1.0.9) & build
  python3 scripts/tools/bump_version.py --minor          # Increment minor (e.g. 1.0.8 -> 1.1.0) & build
  python3 scripts/tools/bump_version.py --set 1.1.0 12   # Set specific version & build
"""

import sys
import re
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent.parent
APP_VERSION_FILE = ROOT_DIR / "scripts" / "core" / "app_version.gd"
PROJECT_GODOT_FILE = ROOT_DIR / "project.godot"
EXPORT_PRESETS_FILE = ROOT_DIR / "export_presets.cfg"

def read_current():
    content = APP_VERSION_FILE.read_text(encoding="utf-8")
    major = int(re.search(r"const MAJOR:\s*int\s*=\s*(\d+)", content).group(1))
    minor = int(re.search(r"const MINOR:\s*int\s*=\s*(\d+)", content).group(1))
    patch = int(re.search(r"const PATCH:\s*int\s*=\s*(\d+)", content).group(1))
    build = int(re.search(r"const BUILD:\s*int\s*=\s*(\d+)", content).group(1))
    return major, minor, patch, build

def write_all(major: int, minor: int, patch: int, build: int):
    ver_name = f"{major}.{minor}.{patch}"
    
    # 1. Update app_version.gd
    app_v_text = f"""class_name AppVersion
extends RefCounted

## Centralized version and build number registry for Project Irene.
## Started at Version 1.0.8, Build 8.

const MAJOR: int = {major}
const MINOR: int = {minor}
const PATCH: int = {patch}
const BUILD: int = {build}

const APP_NAME: String = "Project Irene"
const VERSION_NAME: String = "{ver_name}"

static func get_version_string() -> String:
\treturn "v%s (Build %d)" % [VERSION_NAME, BUILD]

static func get_short_version() -> String:
\treturn "v%s" % VERSION_NAME

static func get_build_string() -> String:
\treturn "Build %d" % BUILD

static func get_full_display() -> String:
\treturn "Version %s • Build %d" % [VERSION_NAME, BUILD]
"""
    APP_VERSION_FILE.write_text(app_v_text, encoding="utf-8")
    print(f"Updated {APP_VERSION_FILE.name}: {ver_name} (Build {build})")

    # 2. Update project.godot
    pg_text = PROJECT_GODOT_FILE.read_text(encoding="utf-8")
    if "config/version=" in pg_text:
        pg_text = re.sub(r'config/version="[^"]*"', f'config/version="{ver_name}"', pg_text)
    else:
        pg_text = pg_text.replace('[application]\n', f'[application]\nconfig/version="{ver_name}"\n')
    PROJECT_GODOT_FILE.write_text(pg_text, encoding="utf-8")
    print(f"Updated {PROJECT_GODOT_FILE.name}: version={ver_name}")

    # 3. Update export_presets.cfg
    if EXPORT_PRESETS_FILE.exists():
        ep_text = EXPORT_PRESETS_FILE.read_text(encoding="utf-8")
        ep_text = re.sub(r'version/code=\d+', f'version/code={build}', ep_text)
        ep_text = re.sub(r'version/name="[^"]*"', f'version/name="{ver_name}"', ep_text)
        ep_text = re.sub(r'application/file_version="[^"]*"', f'application/file_version="{ver_name}"', ep_text)
        ep_text = re.sub(r'application/product_version="[^"]*"', f'application/product_version="{ver_name}"', ep_text)
        EXPORT_PRESETS_FILE.write_text(ep_text, encoding="utf-8")
        print(f"Updated {EXPORT_PRESETS_FILE.name}: code={build}, name={ver_name}")

    print(f"\nSuccessfully set Project Irene to Version {ver_name} (Build {build})!")

def main():
    major, minor, patch, build = read_current()
    if len(sys.argv) < 2 or "--help" in sys.argv or "-h" in sys.argv:
        print(__doc__)
        print(f"Current version: {major}.{minor}.{patch} (Build {build})")
        return

    arg = sys.argv[1]
    if arg == "--build":
        build += 1
    elif arg == "--patch":
        patch += 1
        build += 1
    elif arg == "--minor":
        minor += 1
        patch = 0
        build += 1
    elif arg == "--major":
        major += 1
        minor = 0
        patch = 0
        build += 1
    elif arg == "--set":
        if len(sys.argv) < 4:
            print("Error: --set requires <version> <build_number>")
            return
        parts = [int(p) for p in sys.argv[2].split(".")]
        major, minor, patch = parts[0], parts[1], parts[2]
        build = int(sys.argv[3])
    else:
        print(f"Unknown argument: {arg}")
        print(__doc__)
        return

    write_all(major, minor, patch, build)

if __name__ == "__main__":
    main()

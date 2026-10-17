#!/usr/bin/env python3

import json
import re
import subprocess
import sys

APP_INFO_PATH = "Sources/Swit/CLI/AppInfo.swift"
MANIFEST_PATH = "version.json"
VERSION_PATTERN = r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"


def fail(message):
    print(f"Version check failed: {message}", file=sys.stderr)
    sys.exit(1)

def git(*arguments):
    return subprocess.run(["git", *arguments],
                          capture_output=True,
                          text=True,)

def read_git_file(reference, path):
    result = git("show", f"{reference}:{path}")

    if result.returncode != 0:
        fail(f"Could not read {path} from {reference or 'the index'}.")

    return result.stdout

def parse_version(value):
    if not isinstance(value, str) or not re.fullmatch(VERSION_PATTERN, value):
        fail(f"Invalid version {value!r}. Expected X.Y.Z without leading zeros.")

    return tuple(map(int, value.split(".")))

def read_app_version(content):
    matches = re.findall(r'^\s*static\s+let\s+version\s*=\s*"([^"]+)"\s*$',
                         content,
                         flags=re.MULTILINE,)

    if len(matches) != 1:
        fail("Expected exactly one static let version in AppInfo.swift.")

    return parse_version(matches[0])

def format_version(version):
    return ".".join(map(str, version))

new_version = read_app_version(read_git_file("", APP_INFO_PATH))

try:
    manifest = json.loads(read_git_file("", MANIFEST_PATH))
except json.JSONDecodeError:
    fail("version.json contains invalid JSON.")

if not isinstance(manifest, dict):
    fail("version.json must contain a JSON object.")

manifest_version = parse_version(manifest.get("version"))

if manifest_version != new_version:
    fail("AppInfo.version and version.json must match in the staged files.")

head = git("rev-parse", "--verify", "HEAD")

if head.returncode != 0:
    print(f"Initial version accepted: {format_version(new_version)}")
    sys.exit(0)

previous = git("show", f"HEAD:{APP_INFO_PATH}")

if previous.returncode != 0:
    fail("HEAD has no readable AppInfo.swift. "
        "Define a baseline version before enabling this hook.")

old_version = read_app_version(previous.stdout)
major, minor, patch = old_version

allowed = [
    (major, minor, patch + 1),
    (major, minor + 1, 0),
    (major + 1, 0, 0),
]

if new_version not in allowed:
    options = ", ".join(format_version(version) for version in allowed)
    fail(f"{format_version(old_version)} → {format_version(new_version)} "
         f"is not allowed. Expected one of: {options}. "
         "Update and stage both version files.")

print(f"Version check passed: "
      f"{format_version(old_version)} → {format_version(new_version)}")

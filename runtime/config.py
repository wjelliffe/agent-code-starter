#!/usr/bin/env python3
import json
import os
import subprocess
import sys

DEFAULT = {
    "trunk_branch": "",
    "branch_prefix": "agent/",
    "review_mode": "auto",
    "commands": {"checks": [], "tests": []},
}

def repo_root():
    proc = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    if proc.returncode != 0:
        raise SystemExit("agent-code runtime must be executed inside a git repository")
    return proc.stdout.strip()

def load_config(root=None):
    root = root or repo_root()
    path = os.path.join(root, ".agent-code.json")
    config = json.loads(json.dumps(DEFAULT))
    explicit = {"checks": False, "tests": False}
    if os.path.exists(path):
        try:
            with open(path, "r", encoding="utf-8") as handle:
                raw = json.load(handle)
        except (OSError, json.JSONDecodeError) as exc:
            raise SystemExit(f"invalid .agent-code.json: {exc}")
        if not isinstance(raw, dict):
            raise SystemExit(".agent-code.json must contain a JSON object")
        for key in ("trunk_branch", "branch_prefix", "review_mode"):
            if key in raw:
                if not isinstance(raw[key], str):
                    raise SystemExit(f".agent-code.json {key} must be a string")
                config[key] = raw[key]
        commands = raw.get("commands", {})
        if commands is not None:
            if not isinstance(commands, dict):
                raise SystemExit(".agent-code.json commands must be an object")
            for kind in ("checks", "tests"):
                if kind in commands:
                    explicit[kind] = True
                    value = commands[kind]
                    if not isinstance(value, list) or not all(isinstance(item, str) and item.strip() for item in value):
                        raise SystemExit(f".agent-code.json commands.{kind} must be an array of non-empty strings")
                    config["commands"][kind] = value
    if config["review_mode"] not in {"auto", "required", "optional"}:
        raise SystemExit(".agent-code.json review_mode must be auto, required, or optional")
    prefix = config["branch_prefix"].strip()
    if not prefix:
        raise SystemExit(".agent-code.json branch_prefix must not be empty")
    config["branch_prefix"] = prefix if prefix.endswith("/") else prefix + "/"
    config["_explicit_commands"] = explicit
    config["_path"] = path if os.path.exists(path) else None
    return config

def dotted_get(payload, key):
    value = payload
    for part in key.split("."):
        if not isinstance(value, dict) or part not in value:
            raise KeyError(key)
        value = value[part]
    return value

def main():
    if len(sys.argv) < 2 or sys.argv[1] not in {"get", "dump"}:
        raise SystemExit("usage: config.py <get KEY|dump>")
    config = load_config()
    if sys.argv[1] == "dump":
        print(json.dumps(config, indent=2, sort_keys=True))
        return
    if len(sys.argv) != 3:
        raise SystemExit("usage: config.py get KEY")
    try:
        value = dotted_get(config, sys.argv[2])
    except KeyError:
        raise SystemExit(f"unknown config key: {sys.argv[2]}")
    if isinstance(value, (dict, list, bool)) or value is None:
        print(json.dumps(value))
    else:
        print(value)

if __name__ == "__main__":
    main()

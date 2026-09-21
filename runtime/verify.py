#!/usr/bin/env python3
import importlib.util
import json
import os
import shlex
import subprocess
import sys
import time

from config import load_config, repo_root

def package_manager(root):
    if os.path.exists(os.path.join(root, "pnpm-lock.yaml")):
        return "pnpm"
    if os.path.exists(os.path.join(root, "yarn.lock")):
        return "yarn"
    if os.path.exists(os.path.join(root, "bun.lockb")) or os.path.exists(os.path.join(root, "bun.lock")):
        return "bun"
    return "npm"

def js_commands(root, kind):
    path = os.path.join(root, "package.json")
    if not os.path.exists(path):
        return []
    try:
        with open(path, "r", encoding="utf-8") as handle:
            scripts = (json.load(handle) or {}).get("scripts", {})
    except (OSError, json.JSONDecodeError):
        return []
    wanted = ("typecheck", "lint", "check", "build") if kind == "checks" else ("test", "test:unit", "test:integration")
    pm = package_manager(root)
    commands = []
    for name in wanted:
        if name not in scripts:
            continue
        if pm == "npm":
            commands.append(["npm", "run", name])
        elif pm == "pnpm":
            commands.append(["pnpm", "run", name])
        elif pm == "yarn":
            commands.append(["yarn", name])
        else:
            commands.append(["bun", "run", name])
    return commands

def python_commands(root, kind):
    signals = any(os.path.exists(os.path.join(root, name)) for name in ("pyproject.toml", "setup.py", "setup.cfg", "requirements.txt"))
    tests_dir = os.path.isdir(os.path.join(root, "tests"))
    tracked = subprocess.run(["git", "ls-files", "*.py"], cwd=root, capture_output=True, text=True)
    py_files = [line for line in tracked.stdout.splitlines() if line.strip()]
    if kind == "checks":
        if signals or py_files:
            return [[sys.executable, "-m", "py_compile", *py_files]] if py_files else []
        return []
    if not tests_dir:
        return []
    pytest_configured = os.path.exists(os.path.join(root, "pytest.ini"))
    pyproject = os.path.join(root, "pyproject.toml")
    if os.path.exists(pyproject):
        try:
            with open(pyproject, encoding="utf-8") as handle:
                pytest_configured = pytest_configured or "[tool.pytest" in handle.read()
        except OSError:
            pass
    if pytest_configured or importlib.util.find_spec("pytest") is not None:
        return [[sys.executable, "-m", "pytest", "-q"]]
    return [[sys.executable, "-m", "unittest", "discover", "-s", "tests"]]

def go_commands(root, kind):
    if not os.path.exists(os.path.join(root, "go.mod")):
        return []
    return [["go", "vet", "./..."]] if kind == "checks" else [["go", "test", "./..."]]

def rust_commands(root, kind):
    if not os.path.exists(os.path.join(root, "Cargo.toml")):
        return []
    return [["cargo", "check", "--all-targets"]] if kind == "checks" else [["cargo", "test", "--all-targets"]]

def auto_commands(root, kind):
    commands = []
    for detector in (js_commands, python_commands, go_commands, rust_commands):
        commands.extend(detector(root, kind))
    seen = set()
    unique = []
    for command in commands:
        key = json.dumps(command)
        if key not in seen:
            seen.add(key)
            unique.append(command)
    return unique

def display(command):
    return command if isinstance(command, str) else " ".join(shlex.quote(part) for part in command)

def run_one(command, root):
    started = time.time()
    try:
        proc = subprocess.run(command, cwd=root, capture_output=True, text=True, shell=isinstance(command, str))
        code = proc.returncode
        output = ((proc.stdout or "") + ("\n" if proc.stdout and proc.stderr else "") + (proc.stderr or "")).strip()
    except FileNotFoundError as exc:
        code = 127
        output = str(exc)
    return {
        "command": display(command),
        "status": "pass" if code == 0 else "fail",
        "exit_code": code,
        "duration_seconds": round(time.time() - started, 3),
        "output": output[-6000:],
    }

def main():
    if len(sys.argv) != 2 or sys.argv[1] not in {"checks", "tests"}:
        raise SystemExit("usage: verify.py <checks|tests>")
    kind = sys.argv[1]
    root = repo_root()
    config = load_config(root)
    explicit = config["_explicit_commands"][kind]
    commands = config["commands"][kind] if explicit else auto_commands(root, kind)
    source = "config" if explicit else "auto"
    if not commands:
        print(json.dumps({"ok": True, "kind": kind, "status": "none-found", "source": source, "commands": [], "results": []}, indent=2))
        return
    results = [run_one(command, root) for command in commands]
    failed = [result for result in results if result["status"] == "fail"]
    print(json.dumps({
        "ok": not failed,
        "kind": kind,
        "status": "fail" if failed else "pass",
        "source": source,
        "commands": [display(command) for command in commands],
        "results": results,
    }, indent=2))
    if failed:
        raise SystemExit(1)

if __name__ == "__main__":
    main()

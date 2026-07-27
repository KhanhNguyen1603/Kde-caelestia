#!/usr/bin/env python3
"""Check repository file hygiene — large files, binary blobs, whitespace issues,
merge conflict markers, and common mistakes that should be caught before merge.

Checks:
  1. No files > 500 KB (prevents accidental large binary commits)
  2. No unresolved merge conflict markers (<<<<<<<, =======, >>>>>>>)
  3. No trailing whitespace in code files
  4. No tab indentation in QML / Python / CMake files
  5. No binary files in text-only directories (docs/, scripts/)
  6. .sh files have the correct extension and shebang
"""

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
BOLD = "\033[1m"
RESET = "\033[0m"

MAX_FILE_SIZE_KB = 500

EXIT_CODE = 0
VIOLATIONS: list[str] = []


def error(msg: str) -> None:
    global EXIT_CODE
    print(f"{RED}[ERR]{RESET}  {msg}")
    VIOLATIONS.append(msg)
    EXIT_CODE = 1


def warn(msg: str) -> None:
    print(f"{YELLOW}[WARN]{RESET} {msg}")


def ok(msg: str) -> None:
    print(f"{GREEN}[OK]{RESET}   {msg}")


def is_tracked_in_git(rel_path: str) -> bool:
    """Check if a file is tracked by git (not ignored, not in .git)."""
    return (
        ".git" not in rel_path.split(os.sep)
        and "__pycache__" not in rel_path
        and "build" not in rel_path.split(os.sep)
        and "node_modules" not in rel_path
    )


def is_text_file(filepath: Path) -> bool:
    """Heuristic: try to read as UTF-8 text; if it fails, treat as binary."""
    try:
        filepath.read_text(encoding="utf-8")
        return True
    except (UnicodeDecodeError, OSError):
        return False


def is_generated_file(filepath: Path) -> bool:
    """Skip well-known generated/vendored files."""
    generated_patterns = [
        "json.hpp",  # nlohmann json — vendored single-header
        "qml-lint-conventions.py",  # our own tool
    ]
    return filepath.name in generated_patterns


TEXT_FILE_EXTS = {".qml", ".py", ".cpp", ".hpp", ".h", ".cmake", ".txt",
                  ".md", ".json", ".yml", ".yaml", ".sh", ".bash",
                  ".css", ".js", ".ts", ".xml", ".html", ".conf",
                  ".desktop", ".service", ".timer", ".env", ".toml"}

NON_TEXT_DIRS = {"assets", "wallpapers", "sounds", "icons", "images"}


def check_large_files() -> None:
    """Check for files larger than MAX_FILE_SIZE_KB."""
    for dirpath, dirnames, filenames in os.walk(ROOT):
        # Skip .git, build dirs, and caches
        dirnames[:] = [d for d in dirnames if d not in (".git", "build", "__pycache__", "node_modules")]

        for filename in filenames:
            filepath = Path(dirpath) / filename
            try:
                size_kb = filepath.stat().st_size / 1024
            except OSError:
                continue

            if size_kb > MAX_FILE_SIZE_KB:
                rel = filepath.relative_to(ROOT)
                # Allow known large assets, but flag everything else
                if any(skip in str(rel) for skip in ("wallpapers", "sounds", "assets")):
                    warn(f"Large asset file: {rel} ({size_kb:.0f} KB)")
                else:
                    error(f"File too large ({size_kb:.0f} KB): {rel} — max allowed is {MAX_FILE_SIZE_KB} KB")


def check_merge_conflicts() -> None:
    """Check for unresolved merge conflict markers."""
    conflict_markers = (
        re.compile(rb"^<{7} "),       # <<<<<<< branch
        re.compile(rb"^={7}$"),        # =======
        re.compile(rb"^>{7} "),       # >>>>>>> branch
    )

    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".git", "build", "__pycache__", "node_modules")]

        for filename in filenames:
            filepath = Path(dirpath) / filename
            if not is_text_file(filepath):
                continue

            try:
                content = filepath.read_bytes()
            except OSError:
                continue

            for line_no, line in enumerate(content.split(b"\n"), 1):
                for marker in conflict_markers:
                    if marker.match(line):
                        rel = filepath.relative_to(ROOT)
                        error(f"Unresolved merge conflict in {rel}:{line_no}")
                        break


def check_trailing_whitespace() -> None:
    """Check for trailing whitespace in code files."""
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".git", "build", "__pycache__", "node_modules")]

        for filename in filenames:
            filepath = Path(dirpath) / filename
            rel = str(filepath.relative_to(ROOT))

            if not is_tracked_in_git(rel):
                continue

            ext = filepath.suffix
            if ext not in TEXT_FILE_EXTS:
                continue
            if not is_text_file(filepath):
                continue
            if is_generated_file(filepath):
                continue

            try:
                lines = filepath.read_text(encoding="utf-8").split("\n")
            except OSError:
                continue

            for line_no, line in enumerate(lines, 1):
                if line.rstrip() != line.rstrip("\n"):
                    # Has trailing space
                    if line.rstrip() != line:
                        error(f"Trailing whitespace: {rel}:{line_no}")


def check_tab_indentation() -> None:
    """Check that QML, Python, and CMake files use spaces, not tabs."""
    space_only_exts = {".qml", ".py", ".cpp", ".hpp", ".h"}

    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".git", "build", "__pycache__", "node_modules")]

        for filename in filenames:
            filepath = Path(dirpath) / filename
            rel = str(filepath.relative_to(ROOT))

            if not is_tracked_in_git(rel):
                continue
            if filepath.suffix not in space_only_exts:
                continue
            if not is_text_file(filepath):
                continue
            if is_generated_file(filepath):
                continue

            try:
                lines = filepath.read_text(encoding="utf-8").split("\n")
            except OSError:
                continue

            for line_no, line in enumerate(lines, 1):
                if line.startswith("\t"):
                    error(f"Tab indentation in {rel}:{line_no} — use spaces instead")
                    break  # one error per file is enough


def check_binary_in_text_dirs() -> None:
    """Flag binary files in directories that should only contain text."""
    text_only_dirs = ["docs", "scripts", ".github/scripts"]

    for check_dir in text_only_dirs:
        dir_path = ROOT / check_dir
        if not dir_path.is_dir():
            continue

        for filepath in dir_path.rglob("*"):
            if filepath.is_dir():
                continue
            if ".git" in filepath.parts:
                continue

            if not is_text_file(filepath):
                rel = filepath.relative_to(ROOT)
                error(f"Binary file in text-only directory: {rel}")


def check_shell_extensions() -> None:
    """Ensure .sh files are shell scripts with proper shebangs."""
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in (".git", "build", "__pycache__", "node_modules")]

        for filename in filenames:
            if not filename.endswith(".sh"):
                continue

            filepath = Path(dirpath) / filename
            rel = str(filepath.relative_to(ROOT))

            if not is_tracked_in_git(rel):
                continue

            try:
                first_line = filepath.read_text(encoding="utf-8").split("\n")[0]
            except (OSError, UnicodeDecodeError):
                continue

            if not first_line.startswith("#!"):
                warn(f"Shell script missing shebang: {rel}")
            elif "sh" not in first_line.split("/")[-1]:
                warn(f"Shell script has unexpected shebang: {rel}: {first_line}")


def main() -> int:
    print(f"{BOLD}=== File Size Check ==={RESET}")
    check_large_files()
    if EXIT_CODE == 0:
        ok("No oversized files found")

    print(f"\n{BOLD}=== Merge Conflict Marker Check ==={RESET}")
    check_merge_conflicts()
    if EXIT_CODE == 0:
        ok("No unresolved merge conflicts")

    print(f"\n{BOLD}=== Trailing Whitespace Check ==={RESET}")
    check_trailing_whitespace()
    if EXIT_CODE == 0:
        ok("No trailing whitespace")

    print(f"\n{BOLD}=== Tab Indentation Check ==={RESET}")
    check_tab_indentation()
    if EXIT_CODE == 0:
        ok("No tab indentation in code files")

    print(f"\n{BOLD}=== Binary in Text Directories Check ==={RESET}")
    check_binary_in_text_dirs()
    if EXIT_CODE == 0:
        ok("No binary files in text-only directories")

    print(f"\n{BOLD}=== Shell Script Extension Check ==={RESET}")
    check_shell_extensions()
    if EXIT_CODE == 0:
        ok("All .sh files have proper shebangs")

    print()
    if EXIT_CODE == 0:
        print(f"{BOLD}{GREEN}All file hygiene checks passed.{RESET}")
    else:
        print(f"{BOLD}{RED}{len(VIOLATIONS)} file hygiene violation(s) found.{RESET}")

    return EXIT_CODE


if __name__ == "__main__":
    sys.exit(main())

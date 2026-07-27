#!/usr/bin/env python3
"""Validate that a PR description properly fills out the PR template.

Reads the PR body from the GitHub event payload and checks:
  1. The PR description is not just the default template text
  2. At least one "Type of change" checkbox is checked
  3. At least one "Impact" checkbox is checked
  4. The "Testing" section is filled (not left with placeholder)
  5. The "Review status" section has a selection
  6. Description section has been modified from placeholder
"""

import json
import os
import re
import sys

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
BOLD = "\033[1m"
RESET = "\033[0m"

EXIT_CODE = 0
WARNINGS: list[str] = []


def error(msg: str) -> None:
    global EXIT_CODE
    print(f"{RED}[ERR]{RESET}  {msg}")
    EXIT_CODE = 1


def warn(msg: str) -> None:
    print(f"{YELLOW}[WARN]{RESET} {msg}")
    WARNINGS.append(msg)


def ok(msg: str) -> None:
    print(f"{GREEN}[OK]{RESET}   {msg}")


def load_pr_body() -> str | None:
    """Load PR body from the GitHub event file."""
    event_path = os.environ.get("GITHUB_EVENT_PATH")
    if not event_path:
        print("Warning: GITHUB_EVENT_PATH not set — running locally?")
        return None

    try:
        with open(event_path, encoding="utf-8") as f:
            event = json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        print("Warning: Could not read GitHub event file")
        return None

    pull_request = event.get("pull_request", {})
    return pull_request.get("body", "")


def check_checkbox_section(body: str, section_header: str, min_checked: int = 1) -> bool:
    """Find a section by header and check if at least min_checked boxes are checked."""
    # Find the section
    header_pattern = re.escape(section_header)
    section_match = re.search(
        rf"#{1,3}\s+{header_pattern}.*?\n(.*?)(?=\n#{1,3}\s+|\Z)",
        body,
        re.DOTALL | re.IGNORECASE,
    )
    if not section_match:
        warn(f"Section '{section_header}' not found in PR description")
        return False

    section_text = section_match.group(1)
    # Count checked boxes: - [x] or - [X]
    checked = len(re.findall(r"-\s+\[[xX]\]", section_text))
    total = len(re.findall(r"-\s+\[[ xX]\]", section_text))

    if checked < min_checked:
        error(f"'{section_header}': {checked}/{total} checkboxes checked (need at least {min_checked})")
        return False

    return True


def check_section_not_placeholder(body: str, section_header: str) -> bool:
    """Verify that a section has been filled in (not left with placeholder text)."""
    header_pattern = re.escape(section_header)
    section_match = re.search(
        rf"#{1,3}\s+{header_pattern}.*?\n(.*?)(?=\n#{1,3}\s+|\Z)",
        body,
        re.DOTALL | re.IGNORECASE,
    )
    if not section_match:
        return True  # No section to check

    section_text = section_match.group(1).strip()

    placeholder_texts = [
        "Briefly describe what this PR changes",
        "Describe how you tested these changes",
        "Add screenshots if they are relevant",
        "Add any other context here",
    ]

    for placeholder in placeholder_texts:
        if placeholder.lower() in section_text.lower() and len(section_text) < len(placeholder) + 30:
            warn(f"'{section_header}' appears to still contain placeholder text")
            return False

    # Check if section is essentially empty
    cleaned = re.sub(r"[#\-\*\s]", "", section_text)
    if len(cleaned) < 10:
        warn(f"'{section_header}' section appears empty or minimal")
        return False

    return True


def main() -> int:
    body = load_pr_body()

    if body is None:
        print(f"{YELLOW}Skipping PR template validation — not running in CI context.{RESET}")
        return 0

    print(f"{BOLD}=== PR Template Validation ==={RESET}")

    # 1. Type of change must have at least one checkbox checked
    check_checkbox_section(body, "Type of change", min_checked=1)

    # 2. Impact must have at least one checkbox checked
    check_checkbox_section(body, "Impact", min_checked=1)

    # 3. Review status must be selected (either ready or WIP)
    check_checkbox_section(body, "Review status", min_checked=1)

    # 4. Description section should not be placeholder
    check_section_not_placeholder(body, "Description")

    # 5. Testing section should not be placeholder
    check_section_not_placeholder(body, "Testing")

    # 6. Check that the PR is not empty (no description at all)
    if not body or len(body.strip()) < 20:
        error("PR description is empty or too short")

    print()
    if EXIT_CODE == 0:
        print(f"{BOLD}{GREEN}PR template validation passed.{RESET}")
        if WARNINGS:
            print(f"{YELLOW}(with {len(WARNINGS)} warning(s)){RESET}")
    else:
        print(f"{BOLD}{RED}PR template validation failed — please fill out all sections.{RESET}")

    return EXIT_CODE


if __name__ == "__main__":
    sys.exit(main())

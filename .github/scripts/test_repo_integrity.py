#!/usr/bin/env python3
import py_compile
import re
import shutil
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
INSTALLER_ENTRYPOINTS = [
    Path("setup.sh"),
    Path("update.sh"),
    Path("uninstall.sh"),
]


def repo_files(pattern: str) -> list[Path]:
    return sorted(
        path for path in ROOT.rglob(pattern)
        if ".git" not in path.parts and "__pycache__" not in path.parts and "build" not in path.parts
    )


class ScriptSyntaxTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("bash"), "bash is required for shell syntax checks")
    def test_shell_scripts_parse(self) -> None:
        failures: list[str] = []

        for path in repo_files("*.sh"):
            rel_path = path.relative_to(ROOT).as_posix()
            result = subprocess.run(
                ["bash", "-n", rel_path],
                capture_output=True,
                text=True,
                cwd=ROOT,
            )
            if result.returncode != 0:
                message = (result.stderr or result.stdout).strip()
                failures.append(f"{rel_path}\n{message}")

        self.assertFalse(failures, "Shell syntax failures:\n\n" + "\n\n".join(failures))

    def test_python_scripts_compile(self) -> None:
        failures: list[str] = []

        for path in repo_files("*.py"):
            try:
                py_compile.compile(str(path), doraise=True)
            except py_compile.PyCompileError as exc:
                failures.append(f"{path.relative_to(ROOT)}\n{exc.msg}")

        self.assertFalse(failures, "Python compile failures:\n\n" + "\n\n".join(failures))


class MetadataConsistencyTests(unittest.TestCase):
    def test_shell_version_matches_about_page(self) -> None:
        cmake_text = (ROOT / "shell" / "CMakeLists.txt").read_text(encoding="utf-8")
        about_text = (ROOT / "shell" / "modules" / "nexus" / "pages" / "AboutPage.qml").read_text(
            encoding="utf-8"
        )

        cmake_match = re.search(r'set\(VERSION "(v[0-9]+\.[0-9]+\.[0-9]+)"\)', cmake_text)
        about_match = re.search(r'text:\s*"(v[0-9]+\.[0-9]+\.[0-9]+)"', about_text)

        self.assertIsNotNone(cmake_match, "Could not find shell version in shell/CMakeLists.txt")
        self.assertIsNotNone(about_match, "Could not find About page version label")
        self.assertEqual(cmake_match.group(1), about_match.group(1))

    def test_validation_scripts_referenced_by_docs_exist(self) -> None:
        contributing_text = (ROOT / ".github" / "CONTRIBUTING.md").read_text(encoding="utf-8")

        referenced = [
            ".github/scripts/test_hypr_shim.py",
            "shell/scripts/qml-lint-conventions.py",
        ]

        for rel_path in referenced:
            if rel_path in contributing_text:
                self.assertTrue((ROOT / rel_path).is_file(), f"Missing referenced file: {rel_path}")


class InstallerTests(unittest.TestCase):
    def test_installer_entrypoints_exist(self) -> None:
        for rel_path in INSTALLER_ENTRYPOINTS:
            self.assertTrue((ROOT / rel_path).is_file(), f"Missing installer entrypoint: {rel_path.as_posix()}")

    def test_setup_references_existing_step_scripts(self) -> None:
        setup_text = (ROOT / "setup.sh").read_text(encoding="utf-8")
        matches = re.findall(r'run_step\s+"[^"]+"\s+"\$(SCRIPTS_DIR|BUNDLE_DIR)/([^"]+)"', setup_text)

        self.assertTrue(matches, "No installer steps found in setup.sh")

        for base_dir, rel_path in matches:
            normalized = Path(rel_path.replace("\\", "/"))
            resolved = ROOT / ("scripts" if base_dir == "SCRIPTS_DIR" else "") / normalized
            self.assertTrue(resolved.is_file(), f"Missing installer step referenced by setup.sh: {resolved.relative_to(ROOT).as_posix()}")


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromModule(sys.modules[__name__])
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)
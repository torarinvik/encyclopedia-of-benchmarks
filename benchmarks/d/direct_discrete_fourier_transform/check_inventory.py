"""Source-only package inventory checks."""
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/d/direct_discrete_fourier_transform.c",
    "c3/d/direct_discrete_fourier_transform.c3",
    "cpp/d/direct_discrete_fourier_transform.cpp",
    "elisa/d/direct_discrete_fourier_transform.elisa",
    "mojo/d/direct_discrete_fourier_transform.mojo",
    "nim/d/direct_discrete_fourier_transform.nim",
    "odin/d/direct_discrete_fourier_transform.odin",
    "rust/d/direct_discrete_fourier_transform.rs",
    "v/d/direct_discrete_fourier_transform.v",
    "zig/d/direct_discrete_fourier_transform.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port {relative}")
        elif "direct_discrete_fourier_transform" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing entrypoint marker in {relative}")
        if relative not in readme:
            issues.append(f"README omits {relative}")
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
    print("static inventory is complete")


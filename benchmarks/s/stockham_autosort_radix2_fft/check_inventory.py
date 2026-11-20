"""Source-only inventory checks for the Stockham FFT package."""

from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/s/stockham_autosort_radix2_fft.c",
    "c3/s/stockham_autosort_radix2_fft.c3",
    "cpp/s/stockham_autosort_radix2_fft.cpp",
    "elisa/s/stockham_autosort_radix2_fft.elisa",
    "mojo/s/stockham_autosort_radix2_fft.mojo",
    "nim/s/stockham_autosort_radix2_fft.nim",
    "odin/s/stockham_autosort_radix2_fft.odin",
    "rust/s/stockham_autosort_radix2_fft.rs",
    "v/s/stockham_autosort_radix2_fft.v",
    "zig/s/stockham_autosort_radix2_fft.zig",
)
REQUIRED_METADATA = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "check_inventory.py", "verify_workload.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port {relative}")
        elif "stockham_autosort_radix2_fft" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing entrypoint marker in {relative}")
        if relative not in readme:
            issues.append(f"README omits {relative}")
    for name in REQUIRED_METADATA:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata {name}")
    return issues

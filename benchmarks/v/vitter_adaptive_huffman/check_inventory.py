"""Static source and package inventory for Vitter Algorithm A."""

from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
PORTS = {
    "c": ROOT / "c/a/adaptive_huffman_pair.c",
    "c3": ROOT / "c3/a/adaptive_huffman_pair.c3",
    "cpp": ROOT / "cpp/a/adaptive_huffman_pair.cpp",
    "elisa": ROOT / "elisa/a/adaptive_huffman_pair.elisa",
    "mojo": ROOT / "mojo/a/adaptive_huffman_pair.mojo",
    "nim": ROOT / "nim/a/adaptive_huffman_pair.nim",
    "odin": ROOT / "odin/a/adaptive_huffman_pair.odin",
    "rust": ROOT / "rust/a/adaptive_huffman_pair.rs",
    "v": ROOT / "v/a/adaptive_huffman_pair.v",
    "zig": ROOT / "zig/a/adaptive_huffman_pair.zig",
}


def static_issues() -> list[str]:
    package = Path(__file__).resolve().parent
    issues = [f"missing {language} source" for language, source in PORTS.items()
              if not source.is_file()]
    for language, source in PORTS.items():
        if source.is_file():
            text = source.read_text(encoding="utf-8")
            if "vitter_adaptive_huffman" not in text:
                issues.append(f"{language} source lacks Vitter export")
            if "fgk_adaptive_huffman" not in text:
                issues.append(f"{language} source lacks FGK export")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (package / name).is_file():
            issues.append(f"missing package artifact: {name}")
    issues.extend(verify_workload())
    return issues

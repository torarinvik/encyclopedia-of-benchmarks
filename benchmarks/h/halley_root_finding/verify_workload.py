"""Expose static workload/reference validation for Halley fixtures."""

from __future__ import annotations

import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from run_float64_pair import validate_halley_root_finding_workload

WORKLOAD = Path(__file__).with_name("workload.json")


def verify_workload() -> None:
    """Check workload metadata and its two numerical references in process."""
    validate_halley_root_finding_workload(
        json.loads(WORKLOAD.read_text(encoding="utf-8")))


if __name__ == "__main__":
    verify_workload()

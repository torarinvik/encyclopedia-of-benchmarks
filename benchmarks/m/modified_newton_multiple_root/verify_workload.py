"""Static workload/reference validator; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
sys.path.insert(0, str(PACKAGE.parents[1]))

from run_float64_pair import validate_modified_newton_multiple_root_workload


def verify_workload() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    validate_modified_newton_multiple_root_workload(workload)


if __name__ == "__main__":
    verify_workload()

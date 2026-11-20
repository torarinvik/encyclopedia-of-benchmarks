"""Package-local static workload verifier; it never executes a benchmark port."""

import json
from pathlib import Path

from .check_inventory import missing_artifacts
from .validation import validate_workload


PACKAGE = Path(__file__).resolve().parent


def verify_workload(workload=None):
    issues = missing_artifacts()
    if issues:
        return issues
    try:
        if workload is None:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        validate_workload(workload)
    except (OSError, ValueError, TypeError, json.JSONDecodeError) as error:
        return [str(error)]
    return []

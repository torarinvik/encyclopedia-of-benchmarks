"""Package-local entry point for static inventory and dual-oracle review."""

from __future__ import annotations

import sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
BENCHMARKS = PACKAGE.parents[1]
if str(BENCHMARKS) not in sys.path:
    sys.path.insert(0, str(BENCHMARKS))

from check_sum_of_exponential_times_polynomial_package import static_issues


if __name__ == "__main__":
    issues = static_issues()
    if issues:
        raise SystemExit("\n".join(issues))

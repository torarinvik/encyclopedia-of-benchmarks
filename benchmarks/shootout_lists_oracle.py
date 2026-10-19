"""Independent sequence-model oracle for Shootout Lists."""
from __future__ import annotations

MIN_RUNS = 0
MAX_RUNS = 10_000
MAX_OUTPUT_BYTES = 4
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _test_one_pass() -> int:
    """Model the upstream node moves with Python sequences and check invariants."""
    original = list(range(1, 101))
    copied = original.copy()
    if copied != original:
        raise AssertionError("initial copy differs")

    staging: list[int] = []
    while copied:
        staging.append(copied.pop(0))
    if copied:
        raise AssertionError("head drain did not empty the copied list")

    while staging:
        copied.append(staging.pop())
    if staging:
        raise AssertionError("tail drain did not empty the staging list")

    original.reverse()
    if (original[0] != 100 or original[-1] != 1 or len(original) != 100
            or copied[0] != 100 or copied[-1] != 1 or original != copied):
        raise AssertionError("reversed lists violate upstream checks")
    return len(original)


def expected_output(runs: int) -> tuple[int, bytes]:
    """Return the exact source stdout for a bounded number of list passes."""
    if type(runs) is not int or not MIN_RUNS <= runs <= MAX_RUNS:
        return INVALID_RESULT, b""
    if runs == 0:
        return 2, b"0\n"
    # Every source pass is deterministic and independent; only the final return
    # value is printed, so one modeled pass establishes the result for all runs.
    return len(str(_test_one_pass()).encode("ascii") + b"\n"), b"100\n"

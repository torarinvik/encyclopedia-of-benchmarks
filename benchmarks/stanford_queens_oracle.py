"""Independent oracle for bounded Stanford Queens stdout."""
from __future__ import annotations

MIN_RUNS = 1
MAX_RUNS = 100
SOLVE_REPETITIONS_PER_PASS = 50
MAX_OUTPUT_BYTES = 292
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _has_eight_queens_solution() -> bool:
    """Check solvability with bit masks, independently of the source arrays."""
    full = (1 << 8) - 1

    def place(columns: int, down: int, up: int) -> bool:
        if columns == full:
            return True
        available = full & ~(columns | down | up)
        while available:
            bit = available & -available
            available ^= bit
            if place(columns | bit, ((down | bit) << 1) & full, (up | bit) >> 1):
                return True
        return False

    return place(0, 0, 0)


def expected_output(runs: int) -> tuple[int, bytes]:
    """Return the source stdout prefix for one through one hundred passes."""
    if type(runs) is not int or not MIN_RUNS <= runs <= MAX_RUNS:
        return INVALID_RESULT, b""
    solvable = _has_eight_queens_solution()
    rows: list[str] = []
    for run in range(runs):
        if not solvable:
            rows.extend([" Error in Queens.\n"] * SOLVE_REPETITIONS_PER_PASS)
        rows.append(f"{run + 1}\n")
    output = "".join(rows).encode("ascii")
    return len(output), output

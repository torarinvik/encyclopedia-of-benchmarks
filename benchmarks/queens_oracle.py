"""Independent oracle for the bounded McGill queens stdout profile."""

from __future__ import annotations

from functools import lru_cache

MAX_N = 14
MAX_OUTPUT_BYTES = 80
INVALID_RESULT = -1
OUTPUT_ERROR = -2


@lru_cache(maxsize=None)
def _count_solutions(n: int) -> int:
    """Count placements with bit masks, independently of the source search."""
    full = (1 << n) - 1

    def visit(columns: int, descending: int, ascending: int) -> int:
        if columns == full:
            return 1
        available = full & ~(columns | descending | ascending)
        count = 0
        while available:
            bit = available & -available
            available ^= bit
            count += visit(columns | bit,
                           ((descending | bit) << 1) & full,
                           (ascending | bit) >> 1)
        return count

    # Reflection across the board's vertical axis pairs the first-row branches.
    total = 2 * sum(visit(1 << column, (1 << (column + 1)) & full,
                          1 << (column - 1) if column else 0)
                    for column in range(n // 2))
    if n % 2:
        middle = 1 << (n // 2)
        total += visit(middle, (middle << 1) & full, middle >> 1)
    return total


def expected_output(n: int) -> tuple[int, bytes]:
    """Return the pinned program's count-only header and summary lines."""
    if type(n) is not int or not 1 <= n <= MAX_N:
        return INVALID_RESULT, b""
    solutions = _count_solutions(n)
    header = f"{n} queen{'s' if n != 1 else ''} on a {n}x{n} board...\n"
    if solutions == 1:
        summary = "...there is 1 solution\n"
    else:
        summary = f"...there are {solutions} solutions\n"
    output = (header + summary).encode("ascii")
    return len(output), output

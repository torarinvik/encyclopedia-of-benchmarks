"""Independent oracle for the bounded TSVC Expansion s258 kernel."""

from __future__ import annotations

from collections.abc import Sequence

MIN_N = 1
MAX_N = 64
MAX_INPUT_LENGTH = 1 + 4 * MAX_N
VALUE_MIN = 0
VALUE_MAX = 2


def expected_result(values: Sequence[int] | None) -> int:
    """Return the check(25) checksum after one scalar-carry sweep."""
    if (
        values is None
        or not isinstance(values, (list, tuple))
        or not 1 + 4 * MIN_N <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int for value in values)
    ):
        return -1
    n = values[0]
    if not MIN_N <= n <= MAX_N or len(values) != 1 + 4 * n:
        return -1
    a = values[1:1 + n]
    c = values[1 + n:1 + 2 * n]
    d = values[1 + 2 * n:1 + 3 * n]
    aa0 = values[1 + 3 * n:]
    if any(value < VALUE_MIN or value > VALUE_MAX for value in (*a, *c, *d, *aa0)):
        return -1

    carried = 0
    b_out: list[int] = []
    e_out: list[int] = []
    for i in range(n):
        if a[i] > 0:
            carried = d[i] * d[i]
        b_out.append(carried * c[i] + d[i])
        e_out.append((carried + 1) * aa0[i])
    return sum(b_out) + sum(e_out)

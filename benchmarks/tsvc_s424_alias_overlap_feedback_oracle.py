"""Independent bounded oracle for TSVC Equivalencing s424."""

from __future__ import annotations

from collections.abc import Sequence

MIN_N = 66
MAX_N = 192
MAX_INPUT_LENGTH = MAX_N + 64
VALUE_MIN = 0
VALUE_MAX = 10


def expected_result(values: Sequence[int] | None) -> int:
    """Return the final source-view checksum after one alias-overlap sweep."""
    if (
        values is None
        or not isinstance(values, (list, tuple))
        or not 1 + MIN_N + 63 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int for value in values)
    ):
        return -1
    n = values[0]
    if not MIN_N <= n <= MAX_N or len(values) != n + 64:
        return -1
    a = list(values[1:1 + n])
    x = [0] * (n + 63)
    prefix = values[1 + n:]
    if len(prefix) != 63:
        return -1
    if any(value < VALUE_MIN or value > VALUE_MAX for value in (*a, *prefix)):
        return -1
    x[:63] = prefix

    # s424 sets xx=array+63 and zero-fills the entire view before this sweep.
    # In-place ascending writes create the source's 64-element feedback path.
    for i in range(n - 1):
        x[i + 64] = x[i] + a[i]
    return sum(x[63:63 + n])

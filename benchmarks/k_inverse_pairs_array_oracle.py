"""Insertion-code DP for the bounded Mahonian inversion distribution."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_N = 128
MAX_K = 512
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3


def _parse(values: Sequence[int] | None) -> tuple[int, int] | None:
    if not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if len(values) != 2:
        return None
    n, k = values
    if not 0 <= n <= MAX_N or not 0 <= k <= MAX_K:
        return None
    return n, k


def expected_result(values: Sequence[int] | None) -> int:
    """Return M(n,k) modulo 1,000,000,007 or -1 for malformed input."""
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, k = parsed
    if k > n * (n - 1) // 2:
        return 0

    previous = [0] * (k + 1)
    previous[0] = 1
    for size in range(1, n + 1):
        current = [0] * (k + 1)
        window = 0
        for inversions in range(k + 1):
            window += previous[inversions]
            if inversions >= size:
                window -= previous[inversions - size]
            window %= MODULUS
            current[inversions] = window
        previous = current
    return previous[k]

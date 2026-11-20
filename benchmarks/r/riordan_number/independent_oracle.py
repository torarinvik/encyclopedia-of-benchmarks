"""Central-trinomial difference reference for bounded Riordan numbers."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import INVALID_RESULT, _parse


def _trinomial_coefficient(n: int, target_height: int) -> int:
    offset = n + 1
    counts = [0] * (2 * n + 3)
    counts[offset] = 1
    for step in range(n):
        following = [0] * len(counts)
        for height in range(-step, step + 1):
            ways = counts[offset + height]
            if ways:
                following[offset + height - 1] += ways
                following[offset + height] += ways
                following[offset + height + 1] += ways
        counts = following
    return counts[offset + target_height]


def _central_trinomial_difference(n: int) -> int:
    return _trinomial_coefficient(n, 0) - _trinomial_coefficient(n, -1)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return R_n as t(n,0)-t(n,-1), or -1 for an invalid frame."""
    n = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if n is None else _central_trinomial_difference(n)

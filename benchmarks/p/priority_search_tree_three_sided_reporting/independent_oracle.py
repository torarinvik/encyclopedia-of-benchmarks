"""Brute-force three-sided query reference, independent of tree structure."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import (
        INVALID_RESULT,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_POINTS,
        MAX_QUERIES,
        MAX_RESULT,
        MAX_Y,
        MIN_Y,
        X_DOMAIN,
    )
except ImportError:
    from primary_oracle import (
        INVALID_RESULT,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_POINTS,
        MAX_QUERIES,
        MAX_RESULT,
        MAX_Y,
        MIN_Y,
        X_DOMAIN,
    )


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    n, q = values[0], values[1]
    if not 0 <= n <= MAX_POINTS or not 0 <= q <= MAX_QUERIES:
        return INVALID_RESULT
    if len(values) != 2 + 3 * n + 3 * q:
        return INVALID_RESULT
    points: list[tuple[int, int, int]] = []
    seen_x: set[int] = set()
    seen_labels: set[int] = set()
    at = 2
    for _ in range(n):
        x, y, label = values[at:at + 3]
        at += 3
        if (not 0 <= x < X_DOMAIN or not MIN_Y <= y <= MAX_Y
                or not 0 <= label < MAX_POINTS or x in seen_x
                or label in seen_labels):
            return INVALID_RESULT
        seen_x.add(x)
        seen_labels.add(label)
        points.append((x, y, label))
    result = 0
    for query_index in range(q):
        x0, x1, y1 = values[at:at + 3]
        at += 3
        if not 0 <= x0 <= x1 < X_DOMAIN or not MIN_Y <= y1 <= MAX_Y:
            return INVALID_RESULT
        mask = 0
        for x, y, label in points:
            if x0 <= x <= x1 and y <= y1:
                mask |= 1 << label
        result |= mask << (8 * query_index)
    return result if 0 <= result <= MAX_RESULT else INVALID_RESULT

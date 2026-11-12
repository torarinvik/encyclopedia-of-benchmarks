"""Independent first-visit-table oracle for functional graph parameters."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
ENCODING_BASE = MAX_N + 1
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    n, node = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= node < n or len(values) != n + 2:
        return INVALID_RESULT
    successor = values[2:]
    if any(not 0 <= target < n for target in successor):
        return INVALID_RESULT

    first_seen = [-1] * n
    step = 0
    while first_seen[node] == -1:
        first_seen[node] = step
        node = successor[node]
        step += 1
    mu = first_seen[node]
    cycle_length = step - first_seen[node]
    return ENCODING_BASE * mu + cycle_length

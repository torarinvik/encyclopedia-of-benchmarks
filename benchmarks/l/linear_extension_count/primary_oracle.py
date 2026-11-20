"""Bottom-up subset-DP reference for counting linear extensions."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 12
MAX_VALID_INPUT_LENGTH = 13
MAX_PARSEABLE_INPUT_LENGTH = 14
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_N or input_length != n + 1:
        return None
    full = (1 << n) - 1
    predecessors = tuple(values[1:])
    if any(mask < 0 or mask & ~full for mask in predecessors):
        return None
    return n, predecessors


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, predecessors = parsed
    full = (1 << n) - 1
    ways = [0] * (full + 1)
    ways[0] = 1
    for prefix in range(full + 1):
        count = ways[prefix]
        if count == 0:
            continue
        remaining = full ^ prefix
        while remaining:
            bit = remaining & -remaining
            vertex = bit.bit_length() - 1
            if predecessors[vertex] & prefix == predecessors[vertex]:
                ways[prefix | bit] += count
            remaining ^= bit
    return ways[full]

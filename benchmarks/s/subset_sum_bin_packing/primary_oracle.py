"""Suffix-reachability subset-sum heuristic for bin packing."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ITEMS = 16
MAX_CAPACITY = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_ITEMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096
OUTPUT_BASE = 10_000
MAX_RESULT = 161_496


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count, capacity = values[:2]
    if (not 1 <= count <= MAX_ITEMS or not 1 <= capacity <= MAX_CAPACITY
            or len(values) != count + 2):
        return None
    sizes = values[2:]
    if any(not 1 <= size <= capacity for size in sizes):
        return None
    return capacity, list(sizes)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    capacity, original_sizes = parsed
    remaining = list(range(len(original_sizes)))
    assigned_bin = [0] * len(original_sizes)
    bin_count = 0

    while remaining:
        # reachable[i][s] states whether a suffix can make exact sum s.
        reachable = [[False] * (capacity + 1) for _ in range(len(remaining) + 1)]
        reachable[-1][0] = True
        for position in range(len(remaining) - 1, -1, -1):
            size = original_sizes[remaining[position]]
            for total in range(capacity + 1):
                reachable[position][total] = reachable[position + 1][total]
                if total >= size and reachable[position + 1][total - size]:
                    reachable[position][total] = True

        target = max(total for total, possible in enumerate(reachable[0]) if possible)
        needed = target
        selected: list[int] = []
        skipped: list[int] = []
        for position, item in enumerate(remaining):
            size = original_sizes[item]
            # Include the earliest remaining item whenever the suffix can
            # still complete an optimal target sum.
            if size <= needed and reachable[position + 1][needed - size]:
                selected.append(item)
                assigned_bin[item] = bin_count
                needed -= size
            else:
                skipped.append(item)
        remaining = skipped
        bin_count += 1

    checksum = sum((index + 1) * (assigned_bin[index] + 1)
                   for index in range(len(original_sizes)))
    return bin_count * OUTPUT_BASE + checksum

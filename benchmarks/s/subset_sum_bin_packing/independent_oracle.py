"""Brute-force subset selection reference for the bin-packing heuristic."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ITEMS = 16
MAX_CAPACITY = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_ITEMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
OUTPUT_BASE = 10_000


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
    capacity, sizes = parsed
    remaining = list(range(len(sizes)))
    assignments = [0] * len(sizes)
    bin_count = 0

    while remaining:
        best_sum = -1
        best_mask = 0
        for mask in range(1, 1 << len(remaining)):
            total = 0
            for position, item in enumerate(remaining):
                if mask & (1 << position):
                    total += sizes[item]
            if total > capacity:
                continue
            # The earliest differing remaining item is the most significant
            # tie-break bit: inclusion wins.
            preference = tuple((mask >> position) & 1
                               for position in range(len(remaining)))
            best_preference = tuple((best_mask >> position) & 1
                                    for position in range(len(remaining)))
            if total > best_sum or (total == best_sum and preference > best_preference):
                best_sum = total
                best_mask = mask

        selected: list[int] = []
        skipped: list[int] = []
        for position, item in enumerate(remaining):
            if best_mask & (1 << position):
                selected.append(item)
                assignments[item] = bin_count
            else:
                skipped.append(item)
        remaining = skipped
        bin_count += 1

    checksum = sum((index + 1) * (assignments[index] + 1)
                   for index in range(len(sizes)))
    return bin_count * OUTPUT_BASE + checksum

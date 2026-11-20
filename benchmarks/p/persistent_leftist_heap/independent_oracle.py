"""Immutable sorted-multiset oracle, independent of heap structure."""

from __future__ import annotations

from bisect import insort

from .primary_oracle import (
    EMPTY_RANK,
    I64_MAX,
    I64_MIN,
    MAX_HEAP_SIZE,
    MAX_KEY,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if not values or not 0 <= values[0] <= MAX_OPERATIONS:
        return -1

    versions = [()]
    cursor = 1
    observed_sum = 0
    observed_xor = 0
    for operation_index in range(values[0]):
        if cursor >= len(values):
            return -1
        kind = values[cursor]
        cursor += 1
        width = 2 if kind in (0, 1) else 1 if kind in (2, 3) else 0
        if not width or cursor + width > len(values):
            return -1
        args = values[cursor:cursor + width]
        cursor += width

        if kind == 0:
            base, key = args
            if (not 0 <= base <= operation_index
                    or not -MAX_KEY <= key <= MAX_KEY):
                return -1
            result = list(versions[base])
            insort(result, key)
            result = tuple(result)
        elif kind == 1:
            left, right = args
            if not (0 <= left <= operation_index and 0 <= right <= operation_index):
                return -1
            first = versions[left]
            second = versions[right]
            merged = []
            a = b = 0
            while a < len(first) and b < len(second):
                if first[a] <= second[b]:
                    merged.append(first[a])
                    a += 1
                else:
                    merged.append(second[b])
                    b += 1
            merged.extend(first[a:])
            merged.extend(second[b:])
            result = tuple(merged)
        elif kind == 2:
            (version,) = args
            if not 0 <= version <= operation_index:
                return -1
            previous = versions[version]
            if previous:
                rank = previous[0] + MAX_KEY
                result = previous[1:]
            else:
                rank = EMPTY_RANK
                result = previous
            observed_sum += rank
            observed_xor ^= rank
        else:
            (version,) = args
            if not 0 <= version <= operation_index:
                return -1
            previous = versions[version]
            rank = previous[0] + MAX_KEY if previous else EMPTY_RANK
            observed_sum += rank
            observed_xor ^= rank
            result = previous

        if len(result) > MAX_HEAP_SIZE:
            return -1
        versions.append(result)

    if cursor != len(values):
        return -1
    return (observed_sum << 15) | observed_xor

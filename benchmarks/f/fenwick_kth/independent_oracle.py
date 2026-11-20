"""Independent direct frequency scan for Fenwick selection fixtures."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import (
        MAX_DELTA, MAX_FREQUENCY, MAX_INPUT_LENGTH, MAX_N, MAX_Q, I64_MIN, I64_MAX,
    )
except ImportError:  # Direct invocation from the package directory.
    from primary_oracle import (
        MAX_DELTA, MAX_FREQUENCY, MAX_INPUT_LENGTH, MAX_N, MAX_Q, I64_MIN, I64_MAX,
    )


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[int], list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 3 * q:
        return None
    frequencies = list(values[2:2 + n])
    if any(value < 0 or value > MAX_FREQUENCY for value in frequencies):
        return None
    operations: list[tuple[int, int, int]] = []
    cursor = 2 + n
    for _ in range(q):
        opcode, first, second = values[cursor:cursor + 3]
        cursor += 3
        if opcode == 0:
            if (not 0 <= first < n or not -MAX_DELTA <= second <= MAX_DELTA
                    or not 0 <= frequencies[first] + second <= MAX_FREQUENCY):
                return None
            frequencies[first] += second
        elif opcode == 1:
            if second != 0:
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return list(values[2:2 + n]), operations


def _scan(frequencies: list[int], rank: int) -> int:
    if rank <= 0:
        return -1
    prefix = 0
    for index, frequency in enumerate(frequencies):
        prefix += frequency
        if prefix >= rank:
            return index
    return -1


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    frequencies, operations = decoded
    query_number = 0
    result = 0
    for opcode, first, second in operations:
        if opcode == 0:
            frequencies[first] += second
        else:
            answer = _scan(frequencies, first)
            result += (query_number + 1) * (answer + 1)
            query_number += 1
    return result

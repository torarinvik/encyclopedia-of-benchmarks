"""Direct immutable-version oracle for the bounded persistent range profile."""

from __future__ import annotations

import struct
from typing import Sequence

MOD = 998_244_353
MAX_N = 16
MAX_Q = 16
MAX_VALUE = MOD - 1
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 6 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES
MAX_INTERNAL_NODE_POOL_BYTES = 131_072


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q or len(values) < 2 + n:
        return None
    initial = list(values[2:2 + n])
    if any(not 0 <= value < MOD for value in initial):
        return None
    versions: dict[int, list[int]] = {-1: initial}
    operation_types: list[int] = []
    cursor = 2 + n
    parsed = []

    def valid_version(index: int, before: int) -> bool:
        return (index == -1 or 0 <= index < before
                and operation_types[index] in (0, 1))

    for i in range(q):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        width = 6 if kind == 0 else 5 if kind == 1 else 4 if kind == 2 else 0
        if width == 0 or cursor + width > len(values):
            return None
        record = tuple(values[cursor:cursor + width])
        cursor += width
        if kind == 0:
            _, base, left, right, mul, add = record
            if (not valid_version(base, i) or not 0 <= left < right <= n
                    or not 1 <= mul < MOD or not 0 <= add < MOD):
                return None
        elif kind == 1:
            _, base, source, left, right = record
            if (not valid_version(base, i) or not valid_version(source, i)
                    or not 0 <= left < right <= n):
                return None
        else:
            _, version, left, right = record
            if not valid_version(version, i) or not 0 <= left < right <= n:
                return None
        parsed.append(record)
        operation_types.append(kind)
    if cursor != len(values):
        return None
    return n, initial, parsed


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, initial, operations = parsed
    versions: dict[int, list[int]] = {-1: initial.copy()}
    answers: list[int] = []
    for i, record in enumerate(operations):
        kind = record[0]
        if kind == 0:
            _, base, left, right, mul, add = record
            current = versions[base].copy()
            for j in range(left, right):
                current[j] = (mul * current[j] + add) % MOD
            versions[i] = current
        elif kind == 1:
            _, base, source, left, right = record
            current = versions[base].copy()
            current[left:right] = versions[source][left:right]
            versions[i] = current
        else:
            _, version, left, right = record
            answers.append(sum(versions[version][left:right]) % MOD)
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(actual_capacity) is not int
            or actual_capacity < 0 or output_is_null
            or actual_capacity < 8 * len(answers)):
        return -2, b""
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload

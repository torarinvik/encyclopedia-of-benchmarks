"""Direct list oracle for the bounded dynamic affine sequence profile."""

from __future__ import annotations

import struct
from typing import Sequence

MOD = 998_244_353
MAX_N = 32
MAX_Q = 32
MAX_LENGTH = 64
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 5 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2


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
    if not 0 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) < 2 + n:
        return None
    sequence = list(values[2:2 + n])
    if any(not 0 <= value < MOD for value in sequence):
        return None
    offset = 2 + n
    operations: list[tuple[int, ...]] = []
    query_count = 0
    for _ in range(q):
        if offset >= len(values):
            return None
        kind = values[offset]
        width = {0: 3, 1: 2, 2: 3, 3: 5, 4: 3}.get(kind)
        if width is None or offset + width > len(values):
            return None
        op = tuple(values[offset:offset + width])
        offset += width
        if kind == 0:
            _, index, value = op
            if not 0 <= index <= len(sequence) or len(sequence) >= MAX_LENGTH or not 0 <= value < MOD:
                return None
            sequence.insert(index, value)
        elif kind == 1:
            _, index = op
            if not 0 <= index < len(sequence):
                return None
            sequence.pop(index)
        else:
            _, left, right = op[:3]
            if not 0 <= left <= right <= len(sequence):
                return None
            if kind == 3:
                _, _, _, mul, add = op
                if not 0 <= mul < MOD or not 0 <= add < MOD:
                    return None
            elif kind == 4:
                query_count += 1
        operations.append(op)
    if offset != len(values):
        return None
    return list(values[2:2 + n]), operations, query_count


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    sequence, operations, query_count = parsed
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return OUTPUT_ERROR, b""
    if output_is_null or effective_capacity < 8 * query_count:
        return OUTPUT_ERROR, b""
    answers: list[int] = []
    for op in operations:
        kind = op[0]
        if kind == 0:
            _, index, value = op
            sequence.insert(index, value)
        elif kind == 1:
            sequence.pop(op[1])
        elif kind == 2:
            _, left, right = op
            sequence[left:right] = reversed(sequence[left:right])
        elif kind == 3:
            _, left, right, mul, add = op
            sequence[left:right] = [(mul * x + add) % MOD for x in sequence[left:right]]
        else:
            _, left, right = op
            answers.append(sum(sequence[left:right]) % MOD)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload

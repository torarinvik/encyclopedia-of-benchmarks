"""Independent direct affine-composition checker for the range-set workload."""

import struct
from typing import Sequence

MAX_N = 64
MAX_Q = 32
MOD = 998_244_353
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_N + 5 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 16_384


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q or len(values) < 2 + 2*n:
        return -1, b""
    maps = []
    offset = 2
    for _ in range(n):
        a, b = values[offset:offset + 2]
        offset += 2
        if not 1 <= a < MOD or not 0 <= b < MOD:
            return -1, b""
        maps.append((a, b))
    operations = []
    output_count = 0
    for _ in range(q):
        if offset >= len(values):
            return -1, b""
        tag = values[offset]
        offset += 1
        if tag == 0:
            if offset + 4 > len(values):
                return -1, b""
            left, right, a, b = values[offset:offset + 4]
            offset += 4
            if not 0 <= left < right <= n or not 1 <= a < MOD or not 0 <= b < MOD:
                return -1, b""
            operations.append((tag, left, right, a, b))
        elif tag == 1:
            if offset + 3 > len(values):
                return -1, b""
            left, right, x = values[offset:offset + 3]
            offset += 3
            if not 0 <= left < right <= n or not 0 <= x < MOD:
                return -1, b""
            operations.append((tag, left, right, x))
            output_count += 1
        else:
            return -1, b""
    if offset != len(values):
        return -1, b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < 8 * output_count:
        return -2, b""

    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, left, right, a, b = operation
            for i in range(left, right):
                maps[i] = (a, b)
        else:
            _, left, right, value = operation
            aggregate_a, aggregate_b = 1, 0
            for i in range(left, right):
                a, b = maps[i]
                aggregate_a, aggregate_b = (
                    a * aggregate_a % MOD,
                    (a * aggregate_b + b) % MOD,
                )
            answers.append((aggregate_a * value + aggregate_b) % MOD)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload

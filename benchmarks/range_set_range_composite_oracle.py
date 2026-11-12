"""Direct per-position oracle for bounded range assignment/composition."""

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
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    offset = 2
    if len(values) < offset + 2 * n:
        return None
    functions = []
    for _ in range(n):
        a, b = values[offset:offset + 2]
        offset += 2
        if not 1 <= a < MOD or not 0 <= b < MOD:
            return None
        functions.append((a, b))
    operations = []
    answer_count = 0
    for _ in range(q):
        if offset >= len(values):
            return None
        kind = values[offset]
        offset += 1
        if kind == 0:
            if offset + 4 > len(values):
                return None
            left, right, c, d = values[offset:offset + 4]
            offset += 4
            if not 0 <= left < right <= n or not 1 <= c < MOD or not 0 <= d < MOD:
                return None
            operations.append((0, left, right, c, d))
        elif kind == 1:
            if offset + 3 > len(values):
                return None
            left, right, x = values[offset:offset + 3]
            offset += 3
            if not 0 <= left < right <= n or not 0 <= x < MOD:
                return None
            operations.append((1, left, right, x))
            answer_count += 1
        else:
            return None
    if offset != len(values):
        return None
    return functions, operations, answer_count


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    functions, operations, answer_count = parsed
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return OUTPUT_ERROR, b""
    if output_is_null or effective_capacity < 8 * answer_count:
        return OUTPUT_ERROR, b""
    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, left, right, c, d = operation
            for index in range(left, right):
                functions[index] = (c, d)
        else:
            _, left, right, x = operation
            value = x
            for index in range(left, right):
                a, b = functions[index]
                value = (a * value + b) % MOD
            answers.append(value)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload

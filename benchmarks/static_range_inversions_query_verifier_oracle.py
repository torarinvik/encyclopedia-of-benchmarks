"""Independent direct pair-count oracle for static range inversions."""

import struct
from typing import Sequence

MAX_N = 128
MAX_Q = 32
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 8192
INVALID_RESULT = -1
OUTPUT_ERROR = -2


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
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q or len(values) != 2 + n + 2 * q:
        return -1, b""
    array = values[2:2 + n]
    if any(not 0 <= value <= MAX_VALUE for value in array):
        return -1, b""
    queries = []
    offset = 2 + n
    for _ in range(q):
        left, right = values[offset:offset + 2]
        offset += 2
        if not 0 <= left < right <= n:
            return -1, b""
        queries.append((left, right))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < 8 * q:
        return -2, b""
    answers = []
    for left, right in queries:
        total = 0
        for i in range(left, right):
            for j in range(i + 1, right):
                if array[i] > array[j]:
                    total += 1
        answers.append(total)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload

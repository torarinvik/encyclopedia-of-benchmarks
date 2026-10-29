"""Independent direct-scan oracle for bounded static range mode queries."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 32
MAX_Q = 16
MAX_VALUE = 1_000_000_000
MAX_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_Q
MAX_OUTPUT_BYTES = 16 * MAX_Q
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def evaluate(values: Sequence[int]) -> list[tuple[int, int]] | None:
    if (not isinstance(values, (list, tuple))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or not 2 <= len(values) <= MAX_INPUT_LENGTH):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    if len(values) != 2 + n + 2 * q:
        return None
    array = values[2:2 + n]
    if any(value < 0 or value > MAX_VALUE for value in array):
        return None
    answers: list[tuple[int, int]] = []
    offset = 2 + n
    for query in range(q):
        left, right = values[offset + 2 * query:offset + 2 * query + 2]
        if not 0 <= left < right <= n:
            return None
        counts: dict[int, int] = {}
        for value in array[left:right]:
            counts[value] = counts.get(value, 0) + 1
        best_value, best_count = min(counts.items(), key=lambda pair: (-pair[1], pair[0]))
        answers.append((best_value, best_count))
    return answers


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    answers = evaluate(values)
    if answers is None:
        return INVALID_RESULT, b""
    payload = b"".join(struct.pack("<qq", value, count) for value, count in answers)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload

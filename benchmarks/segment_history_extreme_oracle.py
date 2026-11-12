"""Direct-array oracle for range updates and historical-maximum queries."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 32
MAX_Q = 32
MAX_VALUE = 1000
MAX_INPUT_VALUES = 2 + MAX_N + 4 * MAX_Q
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[list[int], list[tuple[int, int, int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_VALUES:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 2 + n + 4 * q:
        return None
    initial = list(values[2:2 + n])
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in initial):
        return None
    operations: list[tuple[int, int, int, int]] = []
    offset = 2 + n
    for query_index in range(q):
        op, left, right, arg = values[offset + 4 * query_index:offset + 4 * query_index + 4]
        if op not in (0, 1, 2, 3) or not 0 <= left < right <= n:
            return None
        if op in (0, 1):
            if not -MAX_VALUE <= arg <= MAX_VALUE:
                return None
        elif arg != 0:
            return None
        operations.append((op, left, right, arg))
    return initial, operations


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return ABI status and packed query answers, or an error with no bytes."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    initial, operations = parsed
    current = initial.copy()
    historical = initial.copy()
    answers: list[int] = []
    for op, left, right, arg in operations:
        if op == 0:
            for index in range(left, right):
                current[index] = arg
                historical[index] = max(historical[index], arg)
        elif op == 1:
            for index in range(left, right):
                current[index] += arg
                historical[index] = max(historical[index], current[index])
        elif op == 2:
            answers.append(max(current[left:right]))
        else:
            answers.append(max(historical[left:right]))

    payload = struct.pack("<" + "q" * len(answers), *answers) if answers else b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(payload)):
        return OUTPUT_ERROR_RESULT, b""
    return len(payload), payload


def validate_output(values: Sequence[int] | None, output: bytes) -> bool:
    result, expected = expected_output(values, capacity=MAX_OUTPUT_BYTES)
    return result == len(expected) and output == expected

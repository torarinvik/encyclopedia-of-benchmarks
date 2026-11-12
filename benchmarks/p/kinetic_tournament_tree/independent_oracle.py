"""Direct function evaluation after each translated range update."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N, OUTPUT_ERROR,
    )
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N, OUTPUT_ERROR,
    )


def _parse(values, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return None
    cursor = 2
    if cursor + 2 * n > len(values):
        return None
    slopes, intercepts = [], []
    for _ in range(n):
        slope, intercept = values[cursor], values[cursor + 1]
        cursor += 2
        if not -8 <= slope <= 8 or not -64 <= intercept <= 64:
            return None
        if slopes and slope <= slopes[-1]:
            return None
        slopes.append(slope)
        intercepts.append(intercept)
    operations = []
    query_count = 0
    for _ in range(m):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        if kind == 0:
            if cursor + 4 > len(values):
                return None
            left, right, delta = values[cursor + 1:cursor + 4]
            if not 0 <= left <= right < n or not 1 <= delta <= 8:
                return None
            operations.append((0, left, right, delta))
            cursor += 4
        elif kind == 1:
            if cursor + 3 > len(values):
                return None
            left, right = values[cursor + 1:cursor + 3]
            if not 0 <= left <= right < n:
                return None
            operations.append((1, left, right))
            query_count += 1
            cursor += 3
        else:
            return None
    if cursor != len(values) or query_count == 0:
        return None
    return slopes, intercepts, operations


def _direct(slopes: list[int], intercepts: list[int], operations) -> list[int]:
    values = list(intercepts)
    answers = []
    for operation in operations:
        if operation[0] == 0:
            _, left, right, delta = operation
            for index in range(left, right + 1):
                values[index] += slopes[index] * delta
        else:
            _, left, right = operation
            answers.append(max(values[left:right + 1]))
    return answers


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    slopes, intercepts, operations = parsed
    count = sum(operation[0] == 1 for operation in operations)
    byte_count = 8 * count
    if output_is_null or (output_capacity is not None and output_capacity < byte_count):
        return OUTPUT_ERROR, b""
    answers = _direct(slopes, intercepts, operations)
    return byte_count, b"".join(struct.pack("<q", answer) for answer in answers)

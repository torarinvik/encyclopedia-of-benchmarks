"""Direct interval scan oracle for the bounded segment-add/get-min benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INITIAL_SEGMENTS = 16
MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 226
DOMAIN_LOW = -32
DOMAIN_HIGH = 31
DOMAIN_RIGHT = 32
COEFFICIENT_LIMIT = 1_000
INFINITY_VALUE = 1_000_000_000_000
CHECKSUM_OFFSET = 33_001
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
TASK_URL = "https://judge.yosupo.jp/problem/segment_add_get_min"
SPECIFICATION_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/segment_add_get_min/task.md"


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the weighted query checksum, or -1 for an invalid packed trace.

    This oracle scans every stored interval at a query and does not use a
    segment tree or a Li Chao structure.
    """
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH
    ):
        return INVALID_RESULT
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    initial_count, operation_count = values[0], values[1]
    if not 0 <= initial_count <= MAX_INITIAL_SEGMENTS or not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT

    position = 2
    segments: list[tuple[int, int, int, int]] = []
    for _ in range(initial_count):
        if len(values) - position < 4:
            return INVALID_RESULT
        left, right, slope, intercept = values[position:position + 4]
        if not _valid_segment(left, right, slope, intercept):
            return INVALID_RESULT
        segments.append((left, right, slope, intercept))
        position += 4

    checksum = 0
    query_number = 0
    for _ in range(operation_count):
        if position >= len(values):
            return INVALID_RESULT
        opcode = values[position]
        position += 1
        if opcode == 0:
            if len(values) - position < 4:
                return INVALID_RESULT
            left, right, slope, intercept = values[position:position + 4]
            if not _valid_segment(left, right, slope, intercept):
                return INVALID_RESULT
            segments.append((left, right, slope, intercept))
            position += 4
        elif opcode == 1:
            if position >= len(values):
                return INVALID_RESULT
            x = values[position]
            position += 1
            if not DOMAIN_LOW <= x <= DOMAIN_HIGH:
                return INVALID_RESULT
            covering = [
                slope * x + intercept
                for left, right, slope, intercept in segments
                if left <= x < right
            ]
            answer = min(covering) if covering else INFINITY_VALUE
            query_number += 1
            checksum += query_number * (answer + CHECKSUM_OFFSET)
        else:
            return INVALID_RESULT

    return checksum if position == len(values) else INVALID_RESULT


def _valid_segment(left: int, right: int, slope: int, intercept: int) -> bool:
    return (
        DOMAIN_LOW <= left < right <= DOMAIN_RIGHT
        and -COEFFICIENT_LIMIT <= slope <= COEFFICIENT_LIMIT
        and -COEFFICIENT_LIMIT <= intercept <= COEFFICIENT_LIMIT
    )

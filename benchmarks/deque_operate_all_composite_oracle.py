"""Direct-list oracle for a bounded deque of affine functions."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MODULUS = 998_244_353
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
TASK_URL = "https://judge.yosupo.jp/problem/deque_operate_all_composite"


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Apply every query by scanning the logical deque from front to back."""
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
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT

    position = 1
    functions: list[tuple[int, int]] = []
    checksum = 0
    query_number = 0
    for _ in range(operation_count):
        if position >= len(values):
            return INVALID_RESULT
        opcode = values[position]
        position += 1
        if opcode in (0, 1):
            if len(values) - position < 2:
                return INVALID_RESULT
            a, b = values[position:position + 2]
            position += 2
            if not 1 <= a < MODULUS or not 0 <= b < MODULUS:
                return INVALID_RESULT
            if opcode == 0:
                functions.insert(0, (a, b))
            else:
                functions.append((a, b))
        elif opcode in (2, 3):
            if not functions:
                return INVALID_RESULT
            if opcode == 2:
                functions.pop(0)
            else:
                functions.pop()
        elif opcode == 4:
            if position >= len(values):
                return INVALID_RESULT
            value = values[position]
            position += 1
            if not 0 <= value < MODULUS:
                return INVALID_RESULT
            for a, b in functions:
                value = (a * value + b) % MODULUS
            query_number += 1
            checksum += query_number * (value + 1)
        else:
            return INVALID_RESULT

    return checksum if position == len(values) else INVALID_RESULT

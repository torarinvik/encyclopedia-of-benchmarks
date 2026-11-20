"""Independent ordered-set scan oracle for the bitmap predecessor workload."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, MAX_PARSEABLE_LENGTH, MAX_Q, UNIVERSE,
    )
except ImportError:  # Direct invocation from the package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, MAX_PARSEABLE_LENGTH, MAX_Q, UNIVERSE,
    )


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[tuple[int, int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    q = values[0]
    if not 0 <= q <= MAX_Q or len(values) != 1 + 2 * q:
        return None
    operations: list[tuple[int, int]] = []
    for cursor in range(1, len(values), 2):
        opcode, key = values[cursor:cursor + 2]
        if opcode not in (0, 1, 2, 3, 4) or not 0 <= key < UNIVERSE:
            return None
        operations.append((opcode, key))
    return operations


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _decode(values, input_length, input_is_null)
    if operations is None:
        return -1
    data: set[int] = set()
    result = 0
    for operation_number, (opcode, key) in enumerate(operations, 1):
        if opcode == 0:
            answer = int(key not in data)
            data.add(key)
        elif opcode == 1:
            answer = int(key in data)
            data.discard(key)
        elif opcode == 2:
            answer = int(key in data)
        elif opcode == 3:
            candidate = min((item for item in data if item >= key), default=None)
            answer = 0 if candidate is None else candidate + 1
        else:
            candidate = max((item for item in data if item < key), default=None)
            answer = 0 if candidate is None else candidate + 1
        result += operation_number * answer
    return result

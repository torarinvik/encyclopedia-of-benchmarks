"""Flat-list reference for the logical map operations in a linear-hashing trace."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return -1
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 128:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return -1
    count = values[0]
    if not 0 <= count <= 63 or len(values) != 1 + 2 * count:
        return -1

    present: list[int] = []
    result = 0
    for offset in range(1, len(values), 2):
        opcode, key = values[offset:offset + 2]
        if opcode not in (0, 1, 2) or not -1024 <= key <= 1023:
            return -1
        try:
            at = present.index(key)
            found = True
        except ValueError:
            at = -1
            found = False
        if opcode == 0:
            succeeded = not found
            if succeeded:
                present.append(key)
        elif opcode == 1:
            succeeded = found
            if found:
                present.pop(at)
        else:
            succeeded = found
        result = (result << 1) | int(succeeded)
    return result

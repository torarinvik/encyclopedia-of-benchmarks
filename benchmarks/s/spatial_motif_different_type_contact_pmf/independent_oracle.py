"""Independent arrangement-enumeration oracle for heterotypic contacts."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 5
MAX_PARSEABLE_LENGTH = 6
MAX_OUTPUT_BYTES = 120
WORKSPACE_BYTES = 1024
MAX_SEQUENCE_LENGTH = 10


def _enumerated_histogram(length: int, x1: int, y1: int,
                          x2: int, y2: int) -> tuple[int, list[int]]:
    first = [0] * x1 + [1] * y1 + [2] * (length - x1 - y1)
    histogram = [0] * (length + 1)
    arrangement = [2] * length
    denominator = 0

    def visit(position: int, remaining_x: int, remaining_y: int, remaining_other: int) -> None:
        nonlocal denominator
        if position == length:
            contacts = sum(
                (left == 0 and right == 1) or (left == 1 and right == 0)
                for left, right in zip(first, arrangement)
            )
            histogram[contacts] += 1
            denominator += 1
            return
        if remaining_x:
            arrangement[position] = 0
            visit(position + 1, remaining_x - 1, remaining_y, remaining_other)
        if remaining_y:
            arrangement[position] = 1
            visit(position + 1, remaining_x, remaining_y - 1, remaining_other)
        if remaining_other:
            arrangement[position] = 2
            visit(position + 1, remaining_x, remaining_y, remaining_other - 1)

    visit(length, x2, y2, length - x2 - y2)
    return denominator, histogram


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_LENGTH
    ):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if len(values) != MAX_INPUT_LENGTH or any(
        type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values
    ):
        return -1, b""
    length, x1, y1, x2, y2 = values
    if not 1 <= length <= MAX_SEQUENCE_LENGTH:
        return -1, b""
    if min(x1, y1, x2, y2) < 0 or x1 + y1 > length or x2 + y2 > length:
        return -1, b""

    denominator, numerators = _enumerated_histogram(length, x1, y1, x2, y2)
    expected_numerator = sum(index * count for index, count in enumerate(numerators))
    expected_denominator = denominator
    divisor = math.gcd(expected_numerator, expected_denominator)
    expected_numerator //= divisor
    expected_denominator //= divisor
    words = [length, denominator, *numerators, expected_numerator, expected_denominator]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload

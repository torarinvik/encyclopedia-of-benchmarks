"""Independent bitmap oracle for the bounded interval-container profile."""

from __future__ import annotations

from typing import Sequence

MAX_OPERATIONS = 24
RECORD_WIDTH = 3
MAX_INPUT_LENGTH = 73
MAX_PARSEABLE_INPUT_LENGTH = 74


def run(values: Sequence[int] | None) -> int:
    if values is None or not values or len(values) > MAX_INPUT_LENGTH:
        return -1
    count = values[0]
    if type(count) is not int or count < 0 or count > MAX_OPERATIONS:
        return -1
    if len(values) != 1 + count * RECORD_WIDTH:
        return -1
    cells = [False] * 32
    checksum = 0
    for index in range(count):
        offset = 1 + index * RECORD_WIDTH
        opcode, left, right = values[offset : offset + RECORD_WIDTH]
        if type(opcode) is not int or opcode not in (0, 1):
            return -1
        if type(left) is not int or type(right) is not int:
            return -1
        if not 0 <= left <= right <= 32:
            return -1
        for cell in range(left, right):
            cells[cell] = opcode == 0
        checksum += (index + 1) * sum(cells)
    return checksum


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if input_is_null or values is None:
        return -1
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > len(values)
            or input_length > MAX_PARSEABLE_INPUT_LENGTH):
        return -1
    return run(values[:input_length])

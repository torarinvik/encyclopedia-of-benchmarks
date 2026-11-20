"""Direct row/column reference for a bounded straddling checkerboard."""

from __future__ import annotations

from typing import Sequence

MAX_VALID_INPUT_LENGTH = 96
MAX_PARSEABLE_INPUT_LENGTH = 97
MAX_TEXT_LENGTH = 64
MAX_OUTPUT_BYTES = 128
WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 32 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or input_length is not None and (
                type(input_length) is not int or input_length != len(values))):
        return None
    mode = values[0]
    if mode not in (0, 1):
        return None
    board = tuple(values[1:31])
    holes = tuple(index for index, symbol in enumerate(board[:10]) if symbol == 0)
    if len(holes) != 2:
        return None
    seen: set[int] = set()
    for position, symbol in enumerate(board):
        if position < 10 and symbol == 0:
            continue
        if not 32 <= symbol <= 126 or symbol in seen:
            return None
        seen.add(symbol)
    length = values[31]
    if not 0 <= length <= MAX_TEXT_LENGTH or len(values) != 32 + length:
        return None
    return mode, board, holes, tuple(values[32:])


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(actual_capacity) is not int or actual_capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    mode, board, holes, text = parsed
    hole_a, hole_b = holes
    result = bytearray()
    if mode == 0:
        for symbol in text:
            position = next((position for position, cell in enumerate(board)
                             if cell != 0 and cell == symbol), -1)
            if position < 0:
                return INVALID_RESULT, b""
            if position < 10:
                result.append(ord("0") + position)
            else:
                row_digit = hole_a if position < 20 else hole_b
                result.extend((ord("0") + row_digit, ord("0") + position % 10))
    else:
        index = 0
        while index < len(text):
            value = text[index]
            if not ord("0") <= value <= ord("9"):
                return INVALID_RESULT, b""
            column = value - ord("0")
            if board[column] != 0:
                result.append(board[column])
                index += 1
                continue
            if column not in holes or index + 1 >= len(text):
                return INVALID_RESULT, b""
            next_value = text[index + 1]
            if not ord("0") <= next_value <= ord("9"):
                return INVALID_RESULT, b""
            row = 1 if column == hole_a else 2
            result.append(board[row * 10 + next_value - ord("0")])
            index += 2
    encoded = bytes(result)
    if output_is_null or actual_capacity < len(encoded):
        return OUTPUT_ERROR_RESULT, b""
    return len(encoded), encoded

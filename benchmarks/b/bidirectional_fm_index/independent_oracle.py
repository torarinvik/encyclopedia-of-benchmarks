"""Independent direct-occurrence reference for bidirectional index extensions."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1


def _read_frame(values: Sequence[int] | None, input_is_null: bool,
                input_length: int | None) -> tuple[list[int], list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (tuple, list)):
        return None
    actual_size = len(values)
    if input_length is None:
        input_length = actual_size
    if (type(input_length) is not int or input_length != actual_size
            or not 2 <= input_length <= 195):
        return None
    for item in values:
        if type(item) is not int or item < -(1 << 63) or item >= (1 << 63):
            return None
    text_size = values[0]
    op_count = values[1]
    if text_size < 0 or text_size > 64 or op_count < 0 or op_count > 64:
        return None
    cursor = 2
    if cursor + text_size > actual_size:
        return None
    text = []
    for _ in range(text_size):
        symbol = values[cursor]
        cursor += 1
        if symbol < 1 or symbol > 4:
            return None
        text.append(symbol)
    if cursor + 2 * op_count != actual_size:
        return None
    operations = []
    for _ in range(op_count):
        side = values[cursor]
        symbol = values[cursor + 1]
        cursor += 2
        if side < 0 or side > 1 or symbol < 1 or symbol > 4:
            return None
        operations.append((side, symbol))
    return text, operations


def _occurrence_count(text: list[int], pattern: list[int]) -> int:
    if not pattern or len(pattern) > len(text):
        return 0
    matches = 0
    last_start = len(text) - len(pattern)
    for start in range(last_start + 1):
        matched = True
        for offset, symbol in enumerate(pattern):
            if text[start + offset] != symbol:
                matched = False
                break
        if matched:
            matches += 1
    return matches


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read_frame(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    text, operations = parsed
    pattern: list[int] = []
    result = 0
    for index, (side, symbol) in enumerate(operations, start=1):
        if side == 0:
            pattern.insert(0, symbol)
        else:
            pattern.append(symbol)
        result += index * _occurrence_count(text, pattern)
    return result

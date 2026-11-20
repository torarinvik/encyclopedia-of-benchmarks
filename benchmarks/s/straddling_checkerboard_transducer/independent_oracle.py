"""Codeword-map and prefix-trie reference for checkerboard transduction."""

from __future__ import annotations

from typing import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    INVALID_RESULT,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_TEXT_LENGTH,
    OUTPUT_ERROR_RESULT,
)


def _decode_frame(values: Sequence[int] | None, input_is_null: bool,
                  input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 32 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)
            or input_length is not None and (
                type(input_length) is not int or input_length != len(values))):
        return None
    operation = values[0]
    raw_board = values[1:31]
    size = values[31]
    if operation not in (0, 1) or not 0 <= size <= MAX_TEXT_LENGTH:
        return None
    if len(values) != size + 32:
        return None

    holes = [column for column in range(10) if raw_board[column] == 0]
    if len(holes) != 2:
        return None
    if any(raw_board[index] == 0 for index in range(10, 30)):
        return None
    symbols = [symbol for symbol in raw_board if symbol != 0]
    if (len(symbols) != 28 or any(not 32 <= symbol <= 126 for symbol in symbols)
            or len(set(symbols)) != 28):
        return None

    symbol_codes: dict[int, bytes] = {}
    code_symbols: dict[bytes, int] = {}
    for offset, symbol in enumerate(raw_board):
        if symbol == 0:
            continue
        row, column = divmod(offset, 10)
        code = bytes((48 + column,)) if row == 0 else bytes((48 + holes[row - 1], 48 + column))
        symbol_codes[symbol] = code
        code_symbols[code] = symbol
    return operation, raw_board, holes, tuple(values[32:]), symbol_codes, code_symbols


def _trie_decode(text: tuple[int, ...], code_symbols: dict[bytes, int]):
    root: dict[int | None, object] = {}
    for code, symbol in code_symbols.items():
        node = root
        for digit in code:
            child = node.setdefault(digit, {})
            if not isinstance(child, dict):
                return None
            node = child
        if None in node:
            return None
        node[None] = symbol

    result = bytearray()
    cursor = 0
    while cursor < len(text):
        node = root
        while cursor < len(text):
            digit = text[cursor]
            if not 48 <= digit <= 57 or digit not in node:
                return None
            child = node[digit]
            if not isinstance(child, dict):
                return None
            node = child
            cursor += 1
            if None in node:
                result.append(node[None])
                break
        else:
            return None
    return bytes(result)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(actual_capacity) is not int or actual_capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, b""
    parsed = _decode_frame(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    operation, _board, _holes, text, symbol_codes, code_symbols = parsed
    if operation == 0:
        try:
            result = b"".join(symbol_codes[symbol] for symbol in text)
        except KeyError:
            return INVALID_RESULT, b""
    else:
        decoded = _trie_decode(text, code_symbols)
        if decoded is None:
            return INVALID_RESULT, b""
        result = decoded
    if output_is_null or actual_capacity < len(result):
        return OUTPUT_ERROR_RESULT, b""
    return len(result), result

"""Independent oracle for the bounded S-DES example."""

from __future__ import annotations

import struct
from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 2
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2

P8 = (6, 3, 7, 4, 8, 5, 10, 9)
P10 = (3, 5, 2, 7, 4, 10, 1, 9, 8, 6)
P4 = (2, 4, 3, 1)
IP = (2, 6, 3, 1, 4, 8, 5, 7)
IP_INVERSE = (4, 1, 3, 5, 7, 2, 8, 6)
EXPANSION = (4, 1, 2, 3, 2, 3, 4, 1)
S0 = ((1, 0, 3, 2), (3, 2, 1, 0), (0, 2, 1, 3), (3, 1, 3, 2))
S1 = ((0, 1, 2, 3), (2, 0, 1, 3), (3, 0, 1, 0), (2, 1, 0, 3))


def _permute(value: int, width: int, positions: Sequence[int]) -> int:
    result = 0
    for position in positions:
        result = (result << 1) | ((value >> (width - position)) & 1)
    return result


def _rotate5(value: int, amount: int) -> int:
    amount %= 5
    return ((value << amount) | (value >> (5 - amount))) & 0x1F


def _subkeys(key: int) -> tuple[int, int]:
    permuted = _permute(key, 10, P10)
    left, right = permuted >> 5, permuted & 0x1F
    left, right = _rotate5(left, 1), _rotate5(right, 1)
    first = _permute((left << 5) | right, 10, P8)
    left, right = _rotate5(left, 2), _rotate5(right, 2)
    second = _permute((left << 5) | right, 10, P8)
    return first, second


def _sbox(box: Sequence[Sequence[int]], nibble: int) -> int:
    row = ((nibble & 0b1000) >> 2) | (nibble & 1)
    column = (nibble >> 1) & 0b11
    return box[row][column]


def _fk(state: int, subkey: int) -> int:
    left, right = state >> 4, state & 0x0F
    mixed = _permute(right, 4, EXPANSION) ^ subkey
    substituted = (_sbox(S0, mixed >> 4) << 2) | _sbox(S1, mixed & 0x0F)
    return ((left ^ _permute(substituted, 4, P4)) << 4) | right


def _crypt(message: int, first: int, second: int) -> int:
    state = _permute(message, 8, IP)
    state = _fk(state, first)
    state = ((state & 0x0F) << 4) | (state >> 4)
    state = _fk(state, second)
    return _permute(state, 8, IP_INVERSE)


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the bounded output bytes or the input/output ABI sentinel."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) != MAX_VALID_INPUT_LENGTH
    ):
        return INVALID_RESULT, b""

    key, message = values
    if not 0 <= key <= 1023 or not 0 <= message <= 255:
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""

    first, second = _subkeys(key)
    ciphertext = _crypt(message, first, second)
    recovered = _crypt(ciphertext, second, first)
    output = struct.pack("<BB", ciphertext, recovered)
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output

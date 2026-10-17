"""Bounded oracle for the shared Java/Python Playfair cipher domain."""

from __future__ import annotations

from collections.abc import Sequence

MIN_OPERATION = 0
MAX_OPERATION = 1
ENCRYPT = 0
DECRYPT = 1
MIN_KEY_LENGTH = 0
MAX_KEY_LENGTH = 25
MIN_TEXT_LENGTH = 0
MAX_TEXT_LENGTH = 128
MAX_VALID_INPUT_LENGTH = 3 + MAX_KEY_LENGTH + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
FNV_OFFSET_BASIS = 14_695_981_039_346_656_037
FNV_PRIME = 1_099_511_628_211
U64_MASK = (1 << 64) - 1
LOW63_MASK = (1 << 63) - 1

ALPHABET = "ABCDEFGHIKLMNOPQRSTUVWXYZ"
ALPHABET_BYTES = {ord(letter) for letter in ALPHABET}


def _parse_input(values: Sequence[int]) -> tuple[int, str, str] | None:
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int for value in values)
    ):
        return None

    operation, key_length = values[:2]
    if operation not in (ENCRYPT, DECRYPT):
        return None
    if not MIN_KEY_LENGTH <= key_length <= MAX_KEY_LENGTH:
        return None
    text_length_index = 2 + key_length
    if len(values) <= text_length_index:
        return None

    key_bytes = values[2:text_length_index]
    text_length = values[text_length_index]
    if not MIN_TEXT_LENGTH <= text_length <= MAX_TEXT_LENGTH or text_length % 2:
        return None
    if len(values) != text_length_index + 1 + text_length:
        return None
    text_bytes = values[text_length_index + 1:]
    if any(byte not in ALPHABET_BYTES for byte in key_bytes + text_bytes):
        return None

    if operation == ENCRYPT and any(
        text_bytes[index] == text_bytes[index + 1]
        for index in range(0, text_length, 1)
        if index + 1 < text_length
    ):
        return None

    key = bytes(key_bytes).decode("ascii")
    text = bytes(text_bytes).decode("ascii")
    return operation, key, text


def _key_square(key: str) -> tuple[str, ...]:
    table: list[str] = []
    for letter in key + ALPHABET:
        if letter not in table:
            table.append(letter)
    return tuple(table)


def _transform(operation: int, key: str, text: str) -> bytes:
    table = _key_square(key)
    positions = {letter: divmod(index, 5) for index, letter in enumerate(table)}
    shift = 1 if operation == ENCRYPT else -1
    result: list[str] = []

    for index in range(0, len(text), 2):
        first = text[index]
        second = text[index + 1]
        row1, column1 = positions[first]
        row2, column2 = positions[second]
        if row1 == row2:
            result.append(table[row1 * 5 + (column1 + shift) % 5])
            result.append(table[row2 * 5 + (column2 + shift) % 5])
        elif column1 == column2:
            result.append(table[((row1 + shift) % 5) * 5 + column1])
            result.append(table[((row2 + shift) % 5) * 5 + column2])
        else:
            result.append(table[row1 * 5 + column2])
            result.append(table[row2 * 5 + column1])

    return "".join(result).encode("ascii")


def _fnv1a_low63(output: bytes) -> int:
    value = FNV_OFFSET_BASIS
    for byte in output:
        value = ((value ^ byte) * FNV_PRIME) & U64_MASK
    return value & LOW63_MASK


def expected_result(values: Sequence[int]) -> int:
    """Return the output hash or -1 when packed input is invalid."""
    parsed = _parse_input(values)
    if parsed is None:
        return INVALID_RESULT
    operation, key, text = parsed
    return _fnv1a_low63(_transform(operation, key, text))

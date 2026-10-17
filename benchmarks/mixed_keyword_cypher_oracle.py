"""Oracle for the bounded ASCII form of the pinned mixed-keyword cipher."""

from __future__ import annotations

from collections.abc import Sequence

MAX_KEYWORD_LENGTH = 64
MAX_PLAINTEXT_LENGTH = 512
MAX_INPUT_LENGTH = 2 + MAX_KEYWORD_LENGTH + MAX_PLAINTEXT_LENGTH
MAX_OUTPUT_BYTES = MAX_PLAINTEXT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _ascii_upper(value: int) -> int:
    return value - 32 if ord("a") <= value <= ord("z") else value


def _mapping(keyword: Sequence[int]) -> list[int] | None:
    unique: list[int] = []
    seen = [False] * 26
    for raw in keyword:
        letter = _ascii_upper(raw)
        if ord("A") <= letter <= ord("Z"):
            index = letter - ord("A")
            if not seen[index]:
                seen[index] = True
                unique.append(letter)
    if not unique:
        return None

    shifted = unique + [ord("A") + i for i in range(26) if not seen[i]]
    width = len(unique)
    rows = [shifted[start : start + width] for start in range(0, 26, width)]
    result = [0] * 26
    alphabet_index = 0
    for column in range(width):
        for row in rows:
            if len(row) <= column:
                break
            result[alphabet_index] = row[column]
            alphabet_index += 1
    return result


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the encrypted ASCII bytes or the adapter's ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    keyword_length = values[0]
    if not 1 <= keyword_length <= MAX_KEYWORD_LENGTH:
        return INVALID_RESULT, b""
    plaintext_length_index = 1 + keyword_length
    if plaintext_length_index >= len(values):
        return INVALID_RESULT, b""
    plaintext_length = values[plaintext_length_index]
    if not 0 <= plaintext_length <= MAX_PLAINTEXT_LENGTH:
        return INVALID_RESULT, b""
    if len(values) != plaintext_length_index + 1 + plaintext_length:
        return INVALID_RESULT, b""

    keyword = values[1:plaintext_length_index]
    plaintext = values[plaintext_length_index + 1 :]
    if any(not 0 <= value <= 127 for value in keyword):
        return INVALID_RESULT, b""
    if any(not 0 <= value <= 127 for value in plaintext):
        return INVALID_RESULT, b""
    cipher_map = _mapping(keyword)
    if cipher_map is None:
        return INVALID_RESULT, b""

    output = bytearray()
    for raw in plaintext:
        letter = _ascii_upper(raw)
        if ord("A") <= letter <= ord("Z"):
            output.append(cipher_map[letter - ord("A")])
        else:
            output.append(letter)
    encoded = bytes(output)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded

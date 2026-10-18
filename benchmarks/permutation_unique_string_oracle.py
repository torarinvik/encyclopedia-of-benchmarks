"""Oracle for the bounded C# unique-string permutation variant."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations

MIN_CHAR = 32
MAX_CHAR = 126
MAX_LENGTH = 5
MAX_INPUT_LENGTH = MAX_LENGTH + 2
MAX_OUTPUT_BYTES = 1 + 120 * MAX_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_result(values: Sequence[int] | None) -> bytes | None:
    """Return count byte plus the unique ASCII permutations in ordinal order."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return None
    length = values[0]
    if not 0 <= length <= MAX_LENGTH or len(values) != length + 1:
        return None
    chars = values[1:]
    if any(not MIN_CHAR <= char <= MAX_CHAR for char in chars):
        return None
    word = "".join(chr(char) for char in chars)
    unique = sorted(set(permutations(word)))
    if len(unique) > 255:
        return None
    return bytes([len(unique), *(ord(char) for item in unique for char in item)])


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return encoded bytes and result length, or the ABI error with no writes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    output = expected_result(values)
    if output is None:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output

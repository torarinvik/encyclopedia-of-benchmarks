"""Independent bounded oracle for Java's unique string permutation set."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations

MAX_N = 7
MAX_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_N * 5040
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return INVALID_RESULT, b""
    if input_is_null and output_is_null:
        return INVALID_RESULT, b""
    if input_is_null:
        if ((values is not None and values != [] and values != ())
                or type(input_length) is not int
                or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
            return INVALID_RESULT, b""
        return INVALID_RESULT, b""
    if values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or len(values) < 1
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""

    character_count = values[0]
    characters = values[1:]
    if (not 0 <= character_count <= MAX_N
            or len(characters) != character_count
            or any(character < 0 or character > 127 for character in characters)):
        return INVALID_RESULT, b""

    unique = [] if character_count == 0 else sorted(set(permutations(characters)))
    output = b"".join(bytes(permutation) for permutation in unique)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output

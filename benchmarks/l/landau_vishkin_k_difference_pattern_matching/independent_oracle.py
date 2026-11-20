"""Independent streaming-row Levenshtein reference for endpoint flags."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID,
    MAX_ERRORS,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN_LENGTH,
    MAX_TEXT_LENGTH,
    OUTPUT_ERROR,
)


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[int], list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 3:
        return None
    m, n, k = values[:3]
    if not 1 <= m <= MAX_PATTERN_LENGTH or not 0 <= n <= MAX_TEXT_LENGTH:
        return None
    if not 0 <= k <= MAX_ERRORS or k >= m or len(values) != 3 + m + n:
        return None
    pattern = list(values[3:3 + m])
    text = list(values[3 + m:])
    if any(not 0 <= symbol <= 3 for symbol in pattern + text):
        return None
    return pattern, text, k


def _streaming_flags(pattern: list[int], text: list[int], errors: int) -> bytes:
    row = list(range(len(pattern) + 1))
    flags = bytearray()
    for text_symbol in text:
        next_row = [0] * (len(pattern) + 1)
        for pattern_prefix in range(1, len(pattern) + 1):
            substitution = row[pattern_prefix - 1] + (
                pattern[pattern_prefix - 1] != text_symbol
            )
            deletion = next_row[pattern_prefix - 1] + 1
            insertion = row[pattern_prefix] + 1
            next_row[pattern_prefix] = min(substitution, deletion, insertion)
        row = next_row
        flags.append(1 if row[-1] <= errors else 0)
    return bytes(flags)


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    pattern, text, errors = parsed
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(text)):
        return OUTPUT_ERROR, b""
    payload = _streaming_flags(pattern, text, errors)
    return len(payload), payload

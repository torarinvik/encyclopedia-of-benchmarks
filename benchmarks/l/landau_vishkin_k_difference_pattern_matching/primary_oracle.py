"""Landau–Vishkin furthest-reaching diagonal reference with direct LCE."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PATTERN_LENGTH = 16
MAX_TEXT_LENGTH = 32
MAX_ERRORS = 2
MAX_VALID_INPUT_LENGTH = 3 + MAX_PATTERN_LENGTH + MAX_TEXT_LENGTH
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH
WORKSPACE_BYTES = 4096
INVALID = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
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
    pattern_length, text_length, errors = values[:3]
    if not 1 <= pattern_length <= MAX_PATTERN_LENGTH:
        return None
    if not 0 <= text_length <= MAX_TEXT_LENGTH:
        return None
    if not 0 <= errors <= MAX_ERRORS or errors >= pattern_length:
        return None
    if len(values) != 3 + pattern_length + text_length:
        return None
    pattern = list(values[3:3 + pattern_length])
    text = list(values[3 + pattern_length:])
    if any(symbol < 0 or symbol > 3 for symbol in pattern + text):
        return None
    return pattern, text, errors


def _furthest_diagonal_flags(pattern: list[int], text: list[int],
                             errors: int) -> bytes:
    """Run the published diagonal recurrence; LCE is a bounded direct scan."""
    m = len(pattern)
    n = len(text)
    low_diagonal = -(errors + 1)
    high_diagonal = n + 1
    # Cost columns are indexed by e+1, so column zero denotes e=-1.
    frontier = {
        diagonal: [-1] * (errors + 2)
        for diagonal in range(low_diagonal, high_diagonal + 1)
    }

    # Negative-diagonal seeds encode leading pattern deletions, as in the
    # serial LV initialization. The extra low diagonal is a left sentinel.
    for diagonal in range(low_diagonal, 0):
        magnitude = -diagonal
        frontier[diagonal][magnitude] = magnitude - 1
        frontier[diagonal][magnitude - 1] = magnitude - 2

    flags = bytearray(n)
    for cost in range(errors + 1):
        for diagonal in range(-cost, n + 1):
            same = frontier[diagonal][cost] + 1
            from_left = frontier[diagonal - 1][cost]
            from_right = frontier[diagonal + 1][cost] + 1
            row = min(max(same, from_left, from_right), m)

            while row < m:
                text_index = row + diagonal
                if (text_index < 0 or text_index >= n
                        or pattern[row] != text[text_index]):
                    break
                row += 1

            frontier[diagonal][cost + 1] = row
            if row == m:
                endpoint = diagonal + m
                if 1 <= endpoint <= n:
                    flags[endpoint - 1] = 1

    return bytes(flags)


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    pattern, text, errors = parsed
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(text)):
        return OUTPUT_ERROR, b""
    payload = _furthest_diagonal_flags(pattern, text, errors)
    return len(payload), payload

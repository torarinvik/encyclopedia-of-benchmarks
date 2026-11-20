"""Ryser's permanent formula evaluated in Gray-code subset order."""

from __future__ import annotations

MAX_DIMENSION = 8
ENTRY_MIN = -4
ENTRY_MAX = 4
MAX_VALID_INPUT_LENGTH = 65
MAX_PARSEABLE_INPUT_LENGTH = 66
WORKSPACE_BYTES = 4096
INVALID_RESULT = -(1 << 63)


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n = values[0]
    if not 1 <= n <= MAX_DIMENSION or len(values) != 1 + n * n:
        return None
    entries = values[1:]
    if any(value < ENTRY_MIN or value > ENTRY_MAX for value in entries):
        return None
    return n, entries


def expected_result(values, input_is_null=False, input_length=None):
    """Return Ryser's exact permanent, or INT64_MIN for malformed framing."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    n, entries = parsed
    row_sums = [0] * n
    total = 0
    previous_gray = 0
    for ordinal in range(1 << n):
        gray = ordinal ^ (ordinal >> 1)
        if ordinal:
            changed = gray ^ previous_gray
            column = changed.bit_length() - 1
            delta = 1 if gray & changed else -1
            for row in range(n):
                row_sums[row] += delta * entries[row * n + column]
        product = 1
        for row_sum in row_sums:
            product *= row_sum
        parity = (n + gray.bit_count()) & 1
        total += -product if parity else product
        previous_gray = gray
    return total

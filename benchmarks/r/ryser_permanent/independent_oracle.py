"""Independent permanent reference by direct permutation enumeration."""

from __future__ import annotations

from itertools import permutations

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
    """Sum one product for every bijection from rows to columns."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    n, entries = parsed
    total = 0
    for column_order in permutations(range(n)):
        term = 1
        for row, column in enumerate(column_order):
            term *= entries[row * n + column]
        total += term
    return total

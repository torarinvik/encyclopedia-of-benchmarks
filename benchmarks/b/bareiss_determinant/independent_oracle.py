"""Independent signed-permutation expansion for exact determinants."""

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
    if any(value < ENTRY_MIN or value > ENTRY_MAX for value in values[1:]):
        return None
    return n, tuple(values[1:])


def expected_result(values, input_is_null=False, input_length=None):
    """Enumerate all column permutations and apply their inversion signs."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    n, flat = parsed
    total = 0

    def visit(row, used_columns, product_value, inversion_parity):
        nonlocal total
        if row == n:
            total += -product_value if inversion_parity else product_value
            return
        for column in range(n):
            bit = 1 << column
            if used_columns & bit:
                continue
            larger_used = (used_columns >> (column + 1)).bit_count()
            visit(
                row + 1,
                used_columns | bit,
                product_value * flat[row * n + column],
                inversion_parity ^ (larger_used & 1),
            )

    visit(0, 0, 1, 0)
    return total

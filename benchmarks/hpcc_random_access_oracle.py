"""Independent bounded oracle for the HPCC RandomAccess table-update kernel."""

from __future__ import annotations

MAX_N = 256
MIN_N = 2
MAX_INPUT_LENGTH = 1
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
POLYNOMIAL = 0x7


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the position-weighted digest, or -1 for an invalid input."""
    if (input_is_null or type(input_is_null) is not bool
            or not isinstance(values, (list, tuple))
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))
            or len(values) != 1
            or type(values[0]) is not int):
        return -1

    n = values[0]
    if not MIN_N <= n <= MAX_N or n & (n - 1):
        return -1

    table = list(range(n))
    ran = 1
    for _ in range(4 * n):
        feedback = POLYNOMIAL if ran & (1 << 63) else 0
        ran = ((ran << 1) & MASK64) ^ feedback
        table[ran & (n - 1)] ^= ran

    digest = 0
    for index, value in enumerate(table):
        digest = (digest + (index + 1) * value) & MASK64
    return digest & MASK63

"""Independent oracle for the bounded TSVC s273 dependent conditional loop."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_PASSES = 8
MAX_INPUT_LENGTH = 2 + 5 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    """Return the final sum of A, B, and C, or -1 for invalid input."""
    if values is None or not isinstance(values, (list, tuple)):
        return -1
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1
    if not 7 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1

    n, passes = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= passes <= MAX_PASSES:
        return -1
    if len(values) != 2 + 5 * n or any(not -2 <= value <= 2 for value in values[2:]):
        return -1

    a = list(values[2:2 + n])
    b = list(values[2 + n:2 + 2 * n])
    c = list(values[2 + 2 * n:2 + 3 * n])
    d = values[2 + 3 * n:2 + 4 * n]
    e = values[2 + 4 * n:]
    for _ in range(passes):
        for index, (d_value, e_value) in enumerate(zip(d, e)):
            product = d_value * e_value
            updated_a = a[index] + product
            a[index] = updated_a
            if updated_a < 0:
                b[index] += product
            c[index] += updated_a * d_value
    return sum(a) + sum(b) + sum(c)

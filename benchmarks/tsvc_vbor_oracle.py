"""Independent oracle for the bounded TSVC vbor arithmetic kernel."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 128
MAX_INPUT_LENGTH = 1 + 6 * MAX_N


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    """Return the vbor checksum, or -1 for an invalid input frame."""
    if values is None or not isinstance(values, (list, tuple)):
        return -1
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1
    if not 7 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1

    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 6 * n:
        return -1
    if any(not 0 <= value <= 2 for value in values[1:]):
        return -1

    arrays = [values[1 + array_index * n:1 + (array_index + 1) * n]
              for array_index in range(6)]
    total = 0
    for index in range(n):
        a, b, c, d, e, f = (array[index] for array in arrays)
        # These four products mirror the source's nested elementary-product
        # sums. Under the 0..2 contract they remain exact integers in binary64.
        a1 = a * (b*c + b*d + b*e + b*f + c*d + c*e + c*f + d*e + d*f + e*f)
        b1 = b * (c*d + c*e + c*f + d*e + d*f + e*f)
        c1 = c * (d*e + d*f + e*f)
        d1 = d * e * f
        total += a1 * b1 * c1 * d1
    return total

"""Direct Lagrange-basis construction for bounded polynomial interpolation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 12
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _lagrange_coefficients(xs: list[int], ys: list[int]) -> list[int]:
    n = len(xs)
    result = [0] * n
    for i, (xi, yi) in enumerate(zip(xs, ys)):
        basis = [1]
        denominator = 1
        for j, xj in enumerate(xs):
            if j == i:
                continue
            denominator = denominator * (xi - xj) % MODULUS
            expanded = [0] * (len(basis) + 1)
            for degree, coefficient in enumerate(basis):
                expanded[degree] = (expanded[degree] - coefficient * xj) % MODULUS
                expanded[degree + 1] = (expanded[degree + 1] + coefficient) % MODULUS
            basis = expanded
        scale = yi * pow(denominator, MODULUS - 2, MODULUS) % MODULUS
        for degree, coefficient in enumerate(basis):
            result[degree] = (result[degree] + scale * coefficient) % MODULUS
    return result


def _invalid() -> tuple[int, bytes]:
    return INVALID, b""


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _invalid()
    if input_is_null or not isinstance(values, (list, tuple)):
        return _invalid()
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _invalid()
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return _invalid()

    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return _invalid()
    xs = list(values[1 : 1 + n])
    ys = list(values[1 + n :])
    if any(not 0 <= value < MODULUS for value in xs + ys):
        return _invalid()
    if len(set(xs)) != n:
        return _invalid()

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    coefficients = _lagrange_coefficients(xs, ys)
    return byte_count, b"".join(struct.pack("<q", coefficient) for coefficient in coefficients)

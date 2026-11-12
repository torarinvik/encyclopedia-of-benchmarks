"""q-Newton interpolation for nodes in a geometric progression."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 8
MAX_INPUT_LENGTH = 3 + MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _nodes(a: int, r: int, n: int) -> list[int]:
    points: list[int] = []
    point = a
    for _ in range(n):
        points.append(point)
        point = point * r % MODULUS
    return points


def _q_newton_coefficients(a: int, r: int, ys: list[int]) -> list[int]:
    n = len(ys)
    if n == 0:
        return []
    differences = ys.copy()
    newton = [0] * n
    newton[0] = ys[0]
    for order in range(1, n):
        r_power = pow(r, order, MODULUS)
        for i in range(n - 1, order - 1, -1):
            denominator = a * pow(r, i - order, MODULUS) % MODULUS
            denominator = denominator * (r_power - 1) % MODULUS
            differences[i] = ((differences[i] - differences[i - 1])
                              * pow(denominator, MODULUS - 2, MODULUS)) % MODULUS
        newton[order] = differences[order]

    coefficients = [0] * n
    basis = [1] + [0] * n
    degree = 0
    points = _nodes(a, r, n)
    for order, factor in enumerate(newton):
        for power, basis_coefficient in enumerate(basis[: degree + 1]):
            coefficients[power] = (coefficients[power] + factor * basis_coefficient) % MODULUS
        if order + 1 == n:
            break
        expanded = [0] * (n + 1)
        for power in range(degree + 1):
            expanded[power] = (expanded[power] - basis[power] * points[order]) % MODULUS
            expanded[power + 1] = (expanded[power + 1] + basis[power]) % MODULUS
        basis = expanded
        degree += 1
    return coefficients


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
    n, a, r = values[:3]
    if not 0 <= n <= MAX_N or len(values) != 3 + n:
        return _invalid()
    ys = list(values[3:])
    if not 0 <= a < MODULUS or not 0 <= r < MODULUS or any(not 0 <= y < MODULUS for y in ys):
        return _invalid()
    if len(set(_nodes(a, r, n))) != n:
        return _invalid()

    byte_count = 8 * n
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    coefficients = _q_newton_coefficients(a, r, ys)
    return byte_count, b"".join(struct.pack("<q", coefficient) for coefficient in coefficients)

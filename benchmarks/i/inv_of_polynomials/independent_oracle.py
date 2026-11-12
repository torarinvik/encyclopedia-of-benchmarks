"""Independent modular-linear-system oracle for polynomial inverses."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_LENGTH, MODULUS, OUTPUT_ERROR,
    )
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_LENGTH, MODULUS, OUTPUT_ERROR,
    )


def _trim(poly: list[int]) -> list[int]:
    while poly and poly[-1] == 0:
        poly.pop()
    return poly


def _remainder(dividend: list[int], divisor: list[int]) -> list[int]:
    rem = dividend[:]
    if len(divisor) == 1:
        return []
    inverse_lead = pow(divisor[-1], MODULUS - 2, MODULUS)
    while rem and len(rem) >= len(divisor):
        shift = len(rem) - len(divisor)
        factor = rem[-1] * inverse_lead % MODULUS
        for index, coefficient in enumerate(divisor):
            rem[shift + index] = (rem[shift + index] - factor * coefficient) % MODULUS
        _trim(rem)
    return rem


def _mul(left: list[int], right: list[int]) -> list[int]:
    if not left or not right:
        return []
    result = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            result[i + j] = (result[i + j] + a * b) % MODULUS
    return _trim(result)


def _inverse_by_linear_system(f: list[int], g: list[int]) -> list[int] | None:
    if len(g) == 1:
        return []
    dimension = len(g) - 1
    columns: list[list[int]] = []
    for basis_degree in range(dimension):
        shifted = [0] * basis_degree + f
        residue = _remainder(shifted, g)
        columns.append((residue + [0] * dimension)[:dimension])

    augmented = [
        [columns[column][row] for column in range(dimension)]
        + [1 if row == 0 else 0]
        for row in range(dimension)
    ]
    pivot_rows: list[int] = []
    row = 0
    for column in range(dimension):
        pivot = next((candidate for candidate in range(row, dimension)
                      if augmented[candidate][column] != 0), None)
        if pivot is None:
            continue
        augmented[row], augmented[pivot] = augmented[pivot], augmented[row]
        inverse_pivot = pow(augmented[row][column], MODULUS - 2, MODULUS)
        augmented[row] = [(value * inverse_pivot) % MODULUS for value in augmented[row]]
        for other in range(dimension):
            if other == row:
                continue
            factor = augmented[other][column]
            if factor:
                augmented[other] = [
                    (a - factor * b) % MODULUS
                    for a, b in zip(augmented[other], augmented[row])
                ]
        pivot_rows.append(column)
        row += 1
        if row == dimension:
            break
    if row != dimension:
        return None
    solution = [0] * dimension
    for pivot_row, column in enumerate(pivot_rows):
        solution[column] = augmented[pivot_row][-1]
    return _trim(solution)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID, b""
    if len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return INVALID, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_LENGTH or not 1 <= m <= MAX_LENGTH or len(values) != 2 + n + m:
        return INVALID, b""
    f = list(values[2:2 + n])
    g = list(values[2 + n:])
    if (any(not 0 <= value < MODULUS for value in f + g)
            or f[-1] == 0 or g[-1] == 0):
        return INVALID, b""

    inverse = _inverse_by_linear_system(f, g)
    if inverse is None:
        return INVALID, b""
    byte_count = 8 * len(inverse)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    return byte_count, b"".join(struct.pack("<q", value) for value in inverse)

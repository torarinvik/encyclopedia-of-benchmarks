"""Exact strain-energy finite-difference reference for tetrahedral forces."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_ELEMENTS = 32
MAX_INPUT_LENGTH = 388
MAX_OUTPUT_BYTES = 12 * MAX_ELEMENTS * 8


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count, lame_lambda, lame_mu = values[:3]
    if not 1 <= count <= MAX_ELEMENTS or len(values) != 3 + 12 * count:
        return None
    if not 0 <= lame_lambda <= 16 or not 0 <= lame_mu <= 16:
        return None
    coordinates = list(values[3:])
    if any(not -4 <= coordinate <= 4 for coordinate in coordinates):
        return None
    return count, lame_lambda, lame_mu, coordinates


def _energy(lame_lambda: int, lame_mu: int,
            coordinates: Sequence[int]) -> Fraction:
    points = [coordinates[3 * vertex:3 * vertex + 3] for vertex in range(4)]
    deformation = [[points[column + 1][row] - points[0][row]
                    for column in range(3)] for row in range(3)]
    strain = [[Fraction(deformation[row][column] + deformation[column][row], 2)
               - int(row == column) for column in range(3)]
              for row in range(3)]
    trace = sum(strain[axis][axis] for axis in range(3))
    squared_norm = sum(strain[row][column] ** 2
                       for row in range(3) for column in range(3))
    density = Fraction(lame_lambda, 2) * trace * trace + lame_mu * squared_norm
    return density / 6


def _energy_gradient_forces(lame_lambda: int, lame_mu: int,
                             coordinates: Sequence[int]) -> list[int]:
    forces = []
    for coordinate_index in range(12):
        plus = list(coordinates)
        minus = list(coordinates)
        plus[coordinate_index] += 1
        minus[coordinate_index] -= 1
        derivative = (_energy(lame_lambda, lame_mu, plus)
                      - _energy(lame_lambda, lame_mu, minus)) / 2
        scaled_force = -6 * derivative
        if scaled_force.denominator != 1:
            raise ArithmeticError("scaled tetrahedral force is not integral")
        forces.append(scaled_force.numerator)
    return forces


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, b""
    count, lame_lambda, lame_mu, coordinates = decoded
    result = []
    for element in range(count):
        start = 12 * element
        result.extend(_energy_gradient_forces(
            lame_lambda, lame_mu, coordinates[start:start + 12]))
    encoded = b"".join(struct.pack("<q", value) for value in result)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded

"""Direct linear-tetrahedron stress and nodal-force reference."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ELEMENTS = 32
MAX_VALID_INPUT_LENGTH = 387
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


def _element_forces(lame_lambda: int, lame_mu: int,
                    coordinates: Sequence[int]) -> list[int]:
    points = [coordinates[3 * vertex:3 * vertex + 3] for vertex in range(4)]
    deformation = [[points[column + 1][row] - points[0][row]
                    for column in range(3)] for row in range(3)]
    trace_delta = sum(deformation[axis][axis] for axis in range(3)) - 3
    stress = [[
        lame_lambda * trace_delta * int(row == column)
        + lame_mu * (deformation[row][column] + deformation[column][row]
                     - 2 * int(row == column))
        for column in range(3)] for row in range(3)]
    forces = []
    forces.extend(sum(stress[row][axis] for axis in range(3))
                  for row in range(3))
    forces.extend(-stress[row][0] for row in range(3))
    forces.extend(-stress[row][1] for row in range(3))
    forces.extend(-stress[row][2] for row in range(3))
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
        result.extend(_element_forces(lame_lambda, lame_mu,
                                      coordinates[start:start + 12]))
    encoded = b"".join(struct.pack("<q", value) for value in result)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded

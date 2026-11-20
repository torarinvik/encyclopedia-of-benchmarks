"""Incremental-distance D²-seeding reference with a deterministic draw tape."""

from __future__ import annotations

from collections.abc import Sequence

MAX_POINTS = 32
MAX_DIMENSION = 4
MAX_CENTERS = 8
MAX_INPUT_LENGTH = 140
MAX_OUTPUT_BYTES = MAX_CENTERS * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int, int, list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    point_count, dimension, center_count, first_row = values[:4]
    if (not 1 <= point_count <= MAX_POINTS
            or not 1 <= dimension <= MAX_DIMENSION
            or not 1 <= center_count <= min(MAX_CENTERS, point_count)
            or not 0 <= first_row < point_count):
        return None
    coordinate_count = point_count * dimension
    if len(values) != 4 + coordinate_count + center_count - 1:
        return None
    coordinates = list(values[4:4 + coordinate_count])
    if any(not -16 <= value <= 16 for value in coordinates):
        return None
    draws = list(values[4 + coordinate_count:])
    return point_count, dimension, center_count, first_row, coordinates, draws


def _distance_to_row(coordinates: Sequence[int], dimension: int,
                     point_row: int, center_row: int) -> int:
    point_base = point_row * dimension
    center_base = center_row * dimension
    return sum((coordinates[point_base + axis] - coordinates[center_base + axis]) ** 2
               for axis in range(dimension))


def _run(point_count: int, dimension: int, center_count: int, first_row: int,
         coordinates: Sequence[int], draws: Sequence[int]) -> list[int] | None:
    centers = [first_row]
    nearest = [_distance_to_row(coordinates, dimension, row, first_row)
               for row in range(point_count)]

    for step in range(center_count - 1):
        draw = draws[step]
        total_weight = sum(nearest)
        if total_weight == 0:
            if draw != 0:
                return None
            chosen = next((row for row in range(point_count) if row not in centers), None)
            if chosen is None:
                return None
        else:
            if draw < 0 or draw >= total_weight:
                return None
            cumulative = 0
            chosen = None
            for row, weight in enumerate(nearest):
                cumulative += weight
                if cumulative > draw:
                    chosen = row
                    break
            if chosen is None:
                return None
        centers.append(chosen)
        for row in range(point_count):
            distance = _distance_to_row(coordinates, dimension, row, chosen)
            if distance < nearest[row]:
                nearest[row] = distance
    return centers


def _encode(centers: Sequence[int]) -> bytes:
    return b"".join(row.to_bytes(8, "little", signed=True) for row in centers)


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    point_count, dimension, center_count, first_row, coordinates, draws = parsed
    centers = _run(point_count, dimension, center_count, first_row, coordinates, draws)
    if centers is None:
        return INVALID_RESULT, b""
    encoded = _encode(centers)
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < len(encoded)))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded

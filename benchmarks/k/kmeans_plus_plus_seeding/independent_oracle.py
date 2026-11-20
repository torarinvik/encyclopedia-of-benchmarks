"""Recomputed-distance D² reference with prefix-sum weighted selection."""

from __future__ import annotations

from bisect import bisect_right
from collections.abc import Sequence

MAX_POINTS = 32
MAX_DIMENSION = 4
MAX_CENTERS = 8
MAX_INPUT_LENGTH = 140
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _unpack(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, int, int, tuple[int, ...], tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(item) is not int or not -(1 << 63) <= item < (1 << 63)
                   for item in values)):
        return None
    reported_length = len(values) if input_length is None else input_length
    if type(reported_length) is not int or reported_length != len(values):
        return None
    n, dimensions, k, seed_row = values[0], values[1], values[2], values[3]
    if (n < 1 or n > MAX_POINTS or dimensions < 1 or dimensions > MAX_DIMENSION
            or k < 1 or k > min(MAX_CENTERS, n) or seed_row < 0 or seed_row >= n):
        return None
    point_words = n * dimensions
    if len(values) != 4 + point_words + k - 1:
        return None
    coordinates = tuple(values[4:4 + point_words])
    if any(value < -16 or value > 16 for value in coordinates):
        return None
    return n, dimensions, k, seed_row, coordinates, tuple(values[4 + point_words:])


def _squared_distance(points: Sequence[int], dimensions: int,
                      row: int, center_row: int) -> int:
    point_offset = row * dimensions
    center_offset = center_row * dimensions
    distance = 0
    for axis in range(dimensions):
        delta = points[point_offset + axis] - points[center_offset + axis]
        distance += delta * delta
    return distance


def _recompute(n: int, dimensions: int, k: int, first: int,
               points: Sequence[int], draws: Sequence[int]) -> list[int] | None:
    selected = [first]
    for step in range(k - 1):
        weights = [min(_squared_distance(points, dimensions, row, center)
                       for center in selected) for row in range(n)]
        prefix = []
        total = 0
        for weight in weights:
            total += weight
            prefix.append(total)
        draw = draws[step]
        if total == 0:
            if draw != 0:
                return None
            next_row = next((row for row in range(n) if row not in selected), None)
            if next_row is None:
                return None
        else:
            if draw < 0 or draw >= total:
                return None
            next_row = bisect_right(prefix, draw)
            if next_row == n:
                return None
        selected.append(next_row)
    return selected


def _pack(selected: Sequence[int]) -> bytes:
    data = bytearray()
    for row in selected:
        data.extend(int(row).to_bytes(8, "little", signed=True))
    return bytes(data)


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    parsed = _unpack(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    n, dimensions, k, first, points, draws = parsed
    selected = _recompute(n, dimensions, k, first, points, draws)
    if selected is None:
        return INVALID_RESULT, b""
    encoded = _pack(selected)
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < len(encoded)))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded

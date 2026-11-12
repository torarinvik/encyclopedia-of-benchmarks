"""Exact half-plane/cross-product comparator for polar argument order."""

from __future__ import annotations

from collections.abc import Sequence
from functools import cmp_to_key
import struct

MAX_N = 64
COORD_LIMIT = 1_000_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_N
MAX_OUTPUT_BYTES = 16 * MAX_N
MAX_WORKSPACE_BYTES = 16384
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return None
    points = [(values[i], values[i + 1]) for i in range(1, len(values), 2)]
    if any(abs(x) > COORD_LIMIT or abs(y) > COORD_LIMIT for x, y in points):
        return None
    return points


def _half(point: tuple[int, int]) -> int:
    x, y = point
    if y < 0:
        return 0
    if y == 0 and x >= 0:
        return 1
    return 2


def _compare(left: tuple[int, int], right: tuple[int, int]) -> int:
    hl, hr = _half(left), _half(right)
    if hl != hr:
        return -1 if hl < hr else 1
    cross = left[0] * right[1] - left[1] * right[0]
    if cross:
        return -1 if cross > 0 else 1
    left_radius = left[0] * left[0] + left[1] * left[1]
    right_radius = right[0] * right[0] + right[1] * right[1]
    if left_radius != right_radius:
        return -1 if left_radius < right_radius else 1
    if left != right:
        return -1 if left < right else 1
    return 0


def _sort(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    return sorted(points, key=cmp_to_key(_compare))


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    required = 16 * len(points)
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    flattened = (coordinate for point in _sort(points) for coordinate in point)
    return required, b"".join(struct.pack("<q", value) for value in flattened)

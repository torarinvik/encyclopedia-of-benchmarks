"""Fixed-point oracle for the Euclidean TSP with few inner points."""

from __future__ import annotations

import itertools
import math
import struct
from collections.abc import Sequence

MAX_N = 16
MAX_K = 6
MAX_COORDINATE = 1000
DISTANCE_SCALE = 1000
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1
_INF = 1 << 62


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    n, k = values[0], values[1]
    if not 3 <= n <= MAX_N or not 0 <= k <= min(MAX_K, n - 3):
        return None
    if len(values) != 2 + 3 * n:
        return None

    outer_count = n - k
    outer = list(values[2:2 + outer_count])
    inner = list(values[2 + outer_count:2 + n])
    if (len(outer) != outer_count or len(inner) != k
            or sorted(outer + inner) != list(range(n))):
        return None

    coordinate_values = values[2 + n:]
    points: list[tuple[int, int]] = []
    for index in range(n):
        x, y = coordinate_values[2 * index:2 * index + 2]
        if not -MAX_COORDINATE <= x <= MAX_COORDINATE:
            return None
        if not -MAX_COORDINATE <= y <= MAX_COORDINATE:
            return None
        points.append((x, y))
    if len(set(points)) != n:
        return None

    # The caller supplies the cyclic convex-hull order and the remaining
    # strictly interior points, as assumed by the source algorithm.
    return n, outer, inner, points


def _distance(a: tuple[int, int], b: tuple[int, int]) -> int:
    dx, dy = a[0] - b[0], a[1] - b[1]
    scaled_squared = (dx * dx + dy * dy) * DISTANCE_SCALE * DISTANCE_SCALE
    lower = math.isqrt(scaled_squared)
    upper = lower + 1
    if upper * upper - scaled_squared < scaled_squared - lower * lower:
        return upper
    return lower


def _solve(outer: list[int], inner: list[int], points: list[tuple[int, int]]) -> int:
    n, k = len(outer) + len(inner), len(inner)
    best = _INF

    for order in itertools.permutations(inner):
        previous_outer = [_INF] * (k + 1)
        previous_inner = [_INF] * (k + 1)
        previous_outer[0] = 0

        for j in range(1, k + 1):
            previous_inner[j] = min(
                previous_outer[j - 1]
                + _distance(points[outer[0]], points[order[j - 1]]),
                previous_inner[j - 1]
                + _distance(points[order[j - 2]], points[order[j - 1]])
                if j > 1 else _INF,
            )

        for i in range(1, len(outer)):
            current_outer = [_INF] * (k + 1)
            current_inner = [_INF] * (k + 1)
            boundary = _distance(points[outer[i - 1]], points[outer[i]])
            current_outer[0] = previous_outer[0] + boundary
            for j in range(1, k + 1):
                current_outer[j] = min(
                    previous_outer[j] + boundary,
                    previous_inner[j]
                    + _distance(points[order[j - 1]], points[outer[i]]),
                )
            for j in range(1, k + 1):
                current_inner[j] = min(
                    current_outer[j - 1]
                    + _distance(points[outer[i]], points[order[j - 1]]),
                    current_inner[j - 1]
                    + _distance(points[order[j - 2]], points[order[j - 1]])
                    if j > 1 else _INF,
                )
            previous_outer, previous_inner = current_outer, current_inner

        close_outer = _distance(points[outer[-1]], points[outer[0]])
        candidate = previous_outer[k] + close_outer
        if k:
            candidate = min(
                candidate,
                previous_inner[k]
                + _distance(points[order[-1]], points[outer[0]]),
            )
        best = min(best, candidate)

    return best


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int
             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    _, outer, inner, points = parsed
    result = _solve(outer, inner, points)
    output = struct.pack("<q", result)
    if output_is_null or capacity is not None and capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output

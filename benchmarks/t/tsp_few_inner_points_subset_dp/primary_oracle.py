"""Subset F2 reference with the first-hull-gap recurrence completion."""
from __future__ import annotations

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
    if sorted(outer + inner) != list(range(n)):
        return None
    points: list[tuple[int, int]] = []
    coordinate_offset = 2 + n
    for vertex in range(n):
        x, y = values[coordinate_offset + 2 * vertex:coordinate_offset + 2 * vertex + 2]
        if not -MAX_COORDINATE <= x <= MAX_COORDINATE:
            return None
        if not -MAX_COORDINATE <= y <= MAX_COORDINATE:
            return None
        points.append((x, y))
    if len(set(points)) != n:
        return None
    # Hull order and interior classification are supplied, as assumed by §4.
    return outer, inner, points


def _distance(a: tuple[int, int], b: tuple[int, int]) -> int:
    dx, dy = a[0] - b[0], a[1] - b[1]
    squared = (dx * dx + dy * dy) * DISTANCE_SCALE * DISTANCE_SCALE
    lower = math.isqrt(squared)
    upper = lower + 1
    return upper if upper * upper - squared < squared - lower * lower else lower


def _subset_dp(outer: list[int], inner: list[int],
               points: list[tuple[int, int]]) -> int:
    k = len(inner)
    states = 1 << k
    outer_end = k
    distances = [[_distance(a, b) for b in points] for a in points]
    previous = [[_INF] * (k + 1) for _ in range(states)]
    previous[0][outer_end] = 0

    # Complete the i=1 layer by applying the inner-point recurrence before
    # advancing to outer[1]. This permits a first-gap interior chain.
    for mask in range(states):
        for last in range(k + 1):
            if last < k and not mask & (1 << last):
                continue
            prefix = previous[mask][last]
            if prefix >= _INF:
                continue
            vertex = outer[0] if last == outer_end else inner[last]
            for next_inner in range(k):
                bit = 1 << next_inner
                if mask & bit:
                    continue
                next_mask = mask | bit
                previous[next_mask][next_inner] = min(
                    previous[next_mask][next_inner],
                    prefix + distances[vertex][inner[next_inner]],
                )

    for outer_index in range(1, len(outer)):
        current = [[_INF] * (k + 1) for _ in range(states)]
        next_outer = outer[outer_index]
        previous_outer = outer[outer_index - 1]

        # Equation (3): append the next prescribed hull vertex after S.
        for mask in range(states):
            for last in range(k + 1):
                if last < k and not mask & (1 << last):
                    continue
                prefix = previous[mask][last]
                if prefix >= _INF:
                    continue
                vertex = previous_outer if last == outer_end else inner[last]
                current[mask][outer_end] = min(
                    current[mask][outer_end], prefix + distances[vertex][next_outer])

        # Equation (4): append each still-unvisited interior point.
        # Adding a missing bit always increases the integer mask, so this
        # ascending scan processes every predecessor before its destination.
        for mask in range(states):
            for last in range(k + 1):
                if last < k and not mask & (1 << last):
                    continue
                prefix = current[mask][last]
                if prefix >= _INF:
                    continue
                vertex = next_outer if last == outer_end else inner[last]
                for next_inner in range(k):
                    bit = 1 << next_inner
                    if mask & bit:
                        continue
                    next_mask = mask | bit
                    current[next_mask][next_inner] = min(
                        current[next_mask][next_inner],
                        prefix + distances[vertex][inner[next_inner]],
                    )
        previous = current

    full = states - 1
    best = _INF
    for last in range(k + 1):
        if last < k and not full & (1 << last):
            continue
        vertex = outer[-1] if last == outer_end else inner[last]
        best = min(best, previous[full][last] + distances[vertex][outer[0]])
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
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    outer, inner, points = parsed
    payload = struct.pack("<q", _subset_dp(outer, inner, points))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]

"""Independent full-subset DP verifier for the few-inner-points TSP profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

from tsp_few_inner_points_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    _distance,
    _parse,
)

MAX_OUTPUT_BYTES = 8


def _full_subset_tsp(outer: list[int], inner: list[int],
                     points: list[tuple[int, int]]) -> int:
    n = len(points)
    distances = [[_distance(points[u], points[v]) for v in range(n)]
                 for u in range(n)]
    # This verifier uses the chapter's subset formulation independently from
    # the implementation's enumeration of complete inner-point orders. Outer
    # vertices remain in their supplied cyclic order in both formulations.
    k = len(inner)
    outer_end = k
    subset_count = 1 << k
    previous: list[list[int | None]] = [
        [None] * (k + 1) for _ in range(subset_count)
    ]
    previous[0][outer_end] = 0

    for outer_index in range(1, len(outer)):
        current: list[list[int | None]] = [
            [None] * (k + 1) for _ in range(subset_count)
        ]
        outer_vertex = outer[outer_index]
        previous_outer_vertex = outer[outer_index - 1]

        for mask in range(subset_count):
            for last in range(k + 1):
                if last < k and not mask & (1 << last):
                    continue
                prefix_cost = previous[mask][last]
                if prefix_cost is None:
                    continue
                last_vertex = inner[last] if last < k else previous_outer_vertex
                candidate = prefix_cost + distances[last_vertex][outer_vertex]
                incumbent = current[mask][outer_end]
                if incumbent is None or candidate < incumbent:
                    current[mask][outer_end] = candidate

        # Add interior vertices in subset order, ending at the newly added
        # point. This is the independent subset recurrence for a fixed outer
        # prefix.
        for mask in range(subset_count):
            for last in range(k + 1):
                if last < k and not mask & (1 << last):
                    continue
                prefix_cost = current[mask][last]
                if prefix_cost is None:
                    continue
                last_vertex = inner[last] if last < k else outer_vertex
                for nxt in range(k):
                    bit = 1 << nxt
                    if mask & bit:
                        continue
                    next_mask = mask | bit
                    candidate = prefix_cost + distances[last_vertex][inner[nxt]]
                    incumbent = current[next_mask][nxt]
                    if incumbent is None or candidate < incumbent:
                        current[next_mask][nxt] = candidate
        previous = current

    full = subset_count - 1
    result: int | None = None
    for last in range(k + 1):
        if last < k and not full & (1 << last):
            continue
        prefix_cost = previous[full][last]
        if prefix_cost is None:
            continue
        last_vertex = inner[last] if last < k else outer[-1]
        candidate = prefix_cost + distances[last_vertex][outer[0]]
        if result is None or candidate < result:
            result = candidate
    assert result is not None
    return result


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
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    _, outer, inner, points = parsed
    result = _full_subset_tsp(outer, inner, points)
    output = struct.pack("<q", result)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output

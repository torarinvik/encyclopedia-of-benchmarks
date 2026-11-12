"""Direct strict-containment oracle, independent of angular preprocessing."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        COORD_LIMIT, I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N,
        MAX_Q, OUTPUT_ERROR,
    )
except ImportError:
    from primary_oracle import (
        COORD_LIMIT, I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_M, MAX_N,
        MAX_Q, OUTPUT_ERROR,
    )


def _parse(values, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m, q = values[:3]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or not 1 <= q <= MAX_Q:
        return None
    if len(values) != 3 + 2 * n + 2 * m + 3 * q:
        return None
    cursor = 3
    a_points = []
    for _ in range(n):
        point = (values[cursor], values[cursor + 1])
        cursor += 2
        if any(abs(v) > COORD_LIMIT for v in point):
            return None
        a_points.append(point)
    b_points = []
    for _ in range(m):
        point = (values[cursor], values[cursor + 1])
        cursor += 2
        if any(abs(v) > COORD_LIMIT for v in point):
            return None
        b_points.append(point)
    queries = []
    for _ in range(q):
        query = tuple(values[cursor:cursor + 3])
        cursor += 3
        if any(not 0 <= index < n for index in query):
            return None
        queries.append(query)
    return a_points, b_points, queries


def _cross(a, b, p):
    return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])


def _evaluate(a_points, b_points, queries):
    answers = []
    for ia, ib, ic in queries:
        a, b, c = a_points[ia], a_points[ib], a_points[ic]
        orientation = _cross(a, b, c)
        if orientation == 0:
            answers.append(0)
            continue
        count = 0
        for point in b_points:
            sides = (_cross(a, b, point), _cross(b, c, point), _cross(c, a, point))
            if (all(side > 0 for side in sides) if orientation > 0 else all(side < 0 for side in sides)):
                count += 1
        answers.append(count)
    return answers


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    _, _, queries = parsed
    required = 8 * len(queries)
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    return required, b"".join(struct.pack("<q", value) for value in _evaluate(*parsed))

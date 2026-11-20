"""Two-pass Crust pole selection over supplied Voronoi-cell vertices."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_SAMPLES = 8
MAX_VERTICES_PER_CELL = 8
MAX_VALID_INPUT = 225
MAX_PARSEABLE_INPUT = 226
MAX_OUTPUT_BYTES = 136
WORKSPACE_BYTES = 1024
COORDINATE_LIMIT = 16


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple)) or not values
            or len(values) > MAX_PARSEABLE_INPUT
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_SAMPLES:
        return None
    offset = 1
    samples: list[tuple[int, int, int]] = []
    rows: list[tuple[int, int, int, list[tuple[int, int, int]]]] = []
    sample_set: set[tuple[int, int, int]] = set()
    for _ in range(n):
        if offset + 4 > len(values):
            return None
        sx, sy, sz, count = values[offset:offset + 4]
        offset += 4
        sample = (sx, sy, sz)
        if (any(not -COORDINATE_LIMIT <= c <= COORDINATE_LIMIT for c in sample)
                or sample in sample_set or not 1 <= count <= MAX_VERTICES_PER_CELL
                or offset + 3 * count > len(values)):
            return None
        sample_set.add(sample)
        vertices: list[tuple[int, int, int]] = []
        vertex_set: set[tuple[int, int, int]] = set()
        for _ in range(count):
            vertex = tuple(values[offset:offset + 3])
            offset += 3
            if (any(not -COORDINATE_LIMIT <= c <= COORDINATE_LIMIT for c in vertex)
                    or vertex == sample or vertex in vertex_set):
                return None
            vertex_set.add(vertex)
            vertices.append(vertex)
        samples.append(sample)
        rows.append((sx, sy, sz, vertices))
    if offset != len(values):
        return None
    return n, rows


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, rows = parsed

    selections: list[int] = []
    for sx, sy, sz, vertices in rows:
        positive_index = 0
        positive_distance = -1
        for index, (vx, vy, vz) in enumerate(vertices):
            dx, dy, dz = vx - sx, vy - sy, vz - sz
            distance = dx * dx + dy * dy + dz * dz
            if distance > positive_distance:
                positive_distance = distance
                positive_index = index

        px, py, pz = vertices[positive_index]
        pdx, pdy, pdz = px - sx, py - sy, pz - sz
        negative_index = -1
        negative_distance = -1
        for index, (vx, vy, vz) in enumerate(vertices):
            dx, dy, dz = vx - sx, vy - sy, vz - sz
            if dx * pdx + dy * pdy + dz * pdz >= 0:
                continue
            distance = dx * dx + dy * dy + dz * dz
            if distance > negative_distance:
                negative_distance = distance
                negative_index = index
        selections.extend((positive_index, negative_index))

    words = [n, *selections]
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

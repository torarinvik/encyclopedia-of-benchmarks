"""Brute-force scoring reference for Crust opposite-pole selection."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_OUTPUT_BYTES = 136
WORKSPACE_BYTES = 1024


def _decode(frame: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (input_is_null or not isinstance(frame, (list, tuple)) or not frame
            or len(frame) > 226
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(frame)))
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in frame)):
        return None
    sample_count = frame[0]
    if not 1 <= sample_count <= 8:
        return None
    position = 1
    sites: list[tuple[tuple[int, int, int], list[tuple[int, int, int]]]] = []
    seen_sites: set[tuple[int, int, int]] = set()
    for _site in range(sample_count):
        if position + 4 > len(frame):
            return None
        point = (frame[position], frame[position + 1], frame[position + 2])
        vertex_count = frame[position + 3]
        position += 4
        if (any(v < -16 or v > 16 for v in point) or point in seen_sites
                or not 1 <= vertex_count <= 8 or position + 3 * vertex_count > len(frame)):
            return None
        seen_sites.add(point)
        cell_points: list[tuple[int, int, int]] = []
        seen_cell: set[tuple[int, int, int]] = set()
        for _vertex in range(vertex_count):
            candidate = (frame[position], frame[position + 1], frame[position + 2])
            position += 3
            if (any(v < -16 or v > 16 for v in candidate) or candidate == point
                    or candidate in seen_cell):
                return None
            seen_cell.add(candidate)
            cell_points.append(candidate)
        sites.append((point, cell_points))
    if position != len(frame):
        return None
    return sites


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    sites = _decode(values, input_is_null, input_length)
    if sites is None:
        return -1, b""

    answers = [len(sites)]
    for point, candidates in sites:
        displacements = [tuple(q[axis] - point[axis] for axis in range(3))
                         for q in candidates]
        squared_lengths = [sum(component * component for component in delta)
                           for delta in displacements]
        # Reverse the ordinal in the key so equal distances select its minimum.
        positive = max(range(len(candidates)), key=lambda i: (squared_lengths[i], -i))
        forward = displacements[positive]
        opposite = [i for i, delta in enumerate(displacements)
                    if sum(delta[axis] * forward[axis] for axis in range(3)) < 0]
        negative = max(opposite, key=lambda i: (squared_lengths[i], -i), default=-1)
        answers.extend((positive, negative))

    payload = struct.pack("<" + "q" * len(answers), *answers)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

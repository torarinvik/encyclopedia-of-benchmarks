"""Exact-rational face/corner reference for one Catmull–Clark step."""

from __future__ import annotations

import math
from collections.abc import Sequence
from fractions import Fraction

from .primary_oracle import MAX_EDGES, MAX_FACES, MAX_FACE_DEGREE, MAX_INPUT_LENGTH, MAX_VERTICES


def _integer(value: float, low: int, high: int) -> int | None:
    if not math.isfinite(value) or not value.is_integer() or value < low or value > high:
        return None
    return int(value)


def _read(values: Sequence[float] | None, input_length: int | None,
          input_is_null: bool):
    if (type(input_is_null) is not bool or input_is_null or
        not isinstance(values, (list, tuple)) or
        not 2 <= len(values) <= MAX_INPUT_LENGTH):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    raw: list[float] = []
    for item in values:
        if type(item) not in (int, float):
            return None
        try:
            value = float(item)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(value):
            return None
        raw.append(value)
    vertex_count = _integer(raw[0], 0, MAX_VERTICES)
    face_count = _integer(raw[1], 0, MAX_FACES)
    if vertex_count is None or face_count is None:
        return None
    if vertex_count == face_count == 0 and len(raw) == 2:
        return [], [], {}
    if vertex_count == 0 or face_count == 0:
        return None
    coord_end = 2 + 2 * vertex_count
    if coord_end > len(raw):
        return None
    points = [(Fraction.from_float(raw[2 + 2 * i]), Fraction.from_float(raw[3 + 2 * i]))
              for i in range(vertex_count)]
    cursor = coord_end
    faces: list[list[int]] = []
    for _ in range(face_count):
        if cursor >= len(raw):
            return None
        degree = _integer(raw[cursor], 3, MAX_FACE_DEGREE)
        cursor += 1
        if degree is None or cursor + degree > len(raw):
            return None
        face: list[int] = []
        for item in raw[cursor:cursor + degree]:
            vertex = _integer(item, 0, vertex_count - 1)
            if vertex is None:
                return None
            face.append(vertex)
        if len(set(face)) != degree:
            return None
        faces.append(face)
        cursor += degree
    if cursor != len(raw):
        return None

    edge_faces: dict[tuple[int, int], list[int]] = {}
    for face_id, face in enumerate(faces):
        for i, vertex in enumerate(face):
            other = face[(i + 1) % len(face)]
            edge_faces.setdefault((min(vertex, other), max(vertex, other)), []).append(face_id)
    if len(edge_faces) > MAX_EDGES:
        return None
    if any(len(face_ids) != 2 or face_ids[0] == face_ids[1]
           for face_ids in edge_faces.values()):
        return None

    # Build each link graph directly from the cyclic corners of the input faces.
    for vertex in range(vertex_count):
        link: dict[int, set[int]] = {}
        link_pairs: set[tuple[int, int]] = set()
        incident_corner_count = 0
        for face in faces:
            if vertex not in face:
                continue
            incident_corner_count += 1
            i = face.index(vertex)
            a, b = face[(i - 1) % len(face)], face[(i + 1) % len(face)]
            pair = (min(a, b), max(a, b))
            if pair in link_pairs:
                return None
            link_pairs.add(pair)
            link.setdefault(a, set()).add(b)
            link.setdefault(b, set()).add(a)
        if incident_corner_count < 3 or len(link_pairs) != sum(vertex in edge for edge in edge_faces):
            return None
        if any(len(neighbors) != 2 for neighbors in link.values()):
            return None
        start = next(iter(link), None)
        if start is None:
            return None
        reached = {start}
        pending = [start]
        while pending:
            node = pending.pop()
            for neighbor in link[node]:
                if neighbor not in reached:
                    reached.add(neighbor)
                    pending.append(neighbor)
        if len(reached) != len(link):
            return None
    return points, faces, edge_faces


def _compute(points: list[tuple[Fraction, Fraction]], faces: list[list[int]],
             edge_faces: dict[tuple[int, int], list[int]]) -> list[float]:
    vertex_count = len(points)
    edges = sorted(edge_faces)
    edge_id = {edge: i for i, edge in enumerate(edges)}
    face_points = []
    for face in faces:
        face_points.append(tuple(sum((points[v][axis] for v in face), Fraction(0)) / len(face)
                                 for axis in range(2)))

    old_points = []
    for vertex, point in enumerate(points):
        touching_faces = [i for i, face in enumerate(faces) if vertex in face]
        touching_edges = [edge for edge in edges if vertex in edge]
        valence = len(touching_edges)
        result = []
        for axis in range(2):
            face_total = sum((face_points[i][axis] for i in touching_faces), Fraction(0))
            midpoint_total = sum(((points[a][axis] + points[b][axis]) / 2
                                  for a, b in touching_edges), Fraction(0))
            face_average = face_total / valence
            midpoint_average = midpoint_total / valence
            result.append((face_average + 2 * midpoint_average + (valence - 3) * point[axis])
                          / valence)
        old_points.append(tuple(result))

    edge_points = []
    for edge in edges:
        a, b = edge
        adjacent_faces = edge_faces[edge]
        edge_points.append(tuple((points[a][axis] + points[b][axis] +
                                  face_points[adjacent_faces[0]][axis] +
                                  face_points[adjacent_faces[1]][axis]) / 4
                                 for axis in range(2)))
    new_points = old_points + edge_points + face_points
    output: list[float] = [float(len(new_points)), float(sum(len(face) for face in faces))]
    for point in new_points:
        output.extend((float(point[0]), float(point[1])))
    face_offset = vertex_count + len(edges)
    for face_index, face in enumerate(faces):
        for i, vertex in enumerate(face):
            nxt, prev = face[(i + 1) % len(face)], face[(i - 1) % len(face)]
            edge_next = (min(vertex, nxt), max(vertex, nxt))
            edge_prev = (min(prev, vertex), max(prev, vertex))
            output.extend((float(vertex), float(vertex_count + edge_id[edge_next]),
                           float(face_offset + face_index), float(vertex_count + edge_id[edge_prev])))
    return output


def expected_output(values: Sequence[float] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    parsed = _read(values, input_length, input_is_null)
    if parsed is None or type(output_is_null) is not bool:
        return -1, []
    result = _compute(*parsed)
    if output_is_null:
        return -2, []
    if output_capacity is not None and (type(output_capacity) is not int or
                                        output_capacity < len(result)):
        return -2, []
    return len(result), result

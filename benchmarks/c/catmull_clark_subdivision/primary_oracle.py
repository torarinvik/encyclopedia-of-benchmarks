"""Bounded one-step Catmull–Clark subdivision reference."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_VERTICES = 24
MAX_FACES = 8
MAX_FACE_DEGREE = 8
MAX_EDGES = 32
MAX_INPUT_LENGTH = 122
MAX_OUTPUT_LENGTH = 386
WORKSPACE_BYTES = 8192


def _integer(value: float, low: int, high: int) -> int | None:
    if not math.isfinite(value) or value != math.trunc(value) or not low <= value <= high:
        return None
    return int(value)


def _link_is_cycle(vertex: int, faces: list[list[int]], valence: int) -> bool:
    link_edges: list[tuple[int, int]] = []
    for face in faces:
        if vertex not in face:
            continue
        corner = face.index(vertex)
        before = face[(corner - 1) % len(face)]
        after = face[(corner + 1) % len(face)]
        pair = (min(before, after), max(before, after))
        if pair in link_edges:
            return False
        link_edges.append(pair)
    if len(link_edges) != valence or valence < 3:
        return False
    adjacency: dict[int, list[int]] = {}
    for left, right in link_edges:
        adjacency.setdefault(left, []).append(right)
        adjacency.setdefault(right, []).append(left)
    if any(len(neighbors) != 2 for neighbors in adjacency.values()):
        return False
    start = next(iter(adjacency))
    reached = {start}
    frontier = [start]
    while frontier:
        node = frontier.pop()
        for neighbor in adjacency[node]:
            if neighbor not in reached:
                reached.add(neighbor)
                frontier.append(neighbor)
    return len(reached) == len(adjacency)


def _parse(values: Sequence[float] | None, input_length: int | None,
           input_is_null: bool) -> tuple[list[tuple[float, float]], list[list[int]],
                                        dict[tuple[int, int], list[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    numeric: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            converted = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(converted):
            return None
        numeric.append(converted)

    vertex_count = _integer(numeric[0], 0, MAX_VERTICES)
    face_count = _integer(numeric[1], 0, MAX_FACES)
    if vertex_count is None or face_count is None:
        return None
    if vertex_count == 0 or face_count == 0:
        if vertex_count == 0 and face_count == 0 and len(numeric) == 2:
            return [], [], {}
        return None
    coordinate_end = 2 + 2 * vertex_count
    if coordinate_end > len(numeric):
        return None
    coordinates = [(numeric[2 + 2 * i], numeric[3 + 2 * i])
                   for i in range(vertex_count)]

    position = coordinate_end
    faces: list[list[int]] = []
    for _ in range(face_count):
        if position >= len(numeric):
            return None
        degree = _integer(numeric[position], 3, MAX_FACE_DEGREE)
        position += 1
        if degree is None or position + degree > len(numeric):
            return None
        face: list[int] = []
        for raw_vertex in numeric[position:position + degree]:
            vertex = _integer(raw_vertex, 0, vertex_count - 1)
            if vertex is None:
                return None
            face.append(vertex)
        if len(set(face)) != degree:
            return None
        faces.append(face)
        position += degree
    if position != len(numeric):
        return None

    edge_faces: dict[tuple[int, int], list[int]] = {}
    for face_index, face in enumerate(faces):
        for corner, vertex in enumerate(face):
            following = face[(corner + 1) % len(face)]
            edge = (min(vertex, following), max(vertex, following))
            edge_faces.setdefault(edge, []).append(face_index)
    if len(edge_faces) > MAX_EDGES or any(len(incident) != 2 or incident[0] == incident[1]
                                          for incident in edge_faces.values()):
        return None
    for vertex in range(vertex_count):
        valence = sum(vertex in edge for edge in edge_faces)
        if not _link_is_cycle(vertex, faces, valence):
            return None
    return coordinates, faces, edge_faces


def _scaled_mean(values: list[float]) -> float:
    scale = max((abs(value) for value in values), default=0.0)
    if scale == 0.0:
        return 0.0
    return (sum(value / scale for value in values) / len(values)) * scale


def _scaled_average4(values: tuple[float, float, float, float]) -> float:
    scale = max(abs(value) for value in values)
    if scale == 0.0:
        return 0.0
    return ((values[0] / scale + values[1] / scale +
             values[2] / scale + values[3] / scale) * 0.25) * scale


def _subdivide(coordinates: list[tuple[float, float]], faces: list[list[int]],
               edge_faces: dict[tuple[int, int], list[int]]) -> list[float]:
    vertex_count = len(coordinates)
    edges = sorted(edge_faces)
    edge_rank = {edge: index for index, edge in enumerate(edges)}
    face_points: list[tuple[float, float]] = []
    for face in faces:
        face_points.append(tuple(_scaled_mean([coordinates[v][axis] for v in face])
                                 for axis in range(2)))

    new_vertices: list[tuple[float, float]] = []
    for vertex, point in enumerate(coordinates):
        incident_faces = [index for index, face in enumerate(faces) if vertex in face]
        incident_edges = [edge for edge in edges if vertex in edge]
        valence = len(incident_edges)
        new_point: list[float] = []
        for axis in range(2):
            face_average = _scaled_mean([face_points[index][axis] for index in incident_faces])
            edge_midpoints = [_scaled_mean([coordinates[edge[0]][axis],
                                             coordinates[edge[1]][axis]])
                              for edge in incident_edges]
            edge_average = _scaled_mean(edge_midpoints)
            scale = max(abs(point[axis]), abs(face_average), abs(edge_average))
            if scale == 0.0:
                new_point.append(0.0)
            else:
                weighted = (face_average / scale + 2.0 * edge_average / scale +
                            (valence - 3) * point[axis] / scale) / valence
                new_point.append(weighted * scale)
        new_vertices.append((new_point[0], new_point[1]))

    edge_points: list[tuple[float, float]] = []
    for edge in edges:
        adjacent = edge_faces[edge]
        edge_points.append(tuple(_scaled_average4((coordinates[edge[0]][axis],
            coordinates[edge[1]][axis], face_points[adjacent[0]][axis],
            face_points[adjacent[1]][axis])) for axis in range(2)))

    all_points = new_vertices + edge_points + face_points
    output: list[float] = [float(len(all_points)), float(sum(map(len, faces)))]
    for x_value, y_value in all_points:
        output.extend((x_value, y_value))
    face_offset = vertex_count + len(edges)
    for face_index, face in enumerate(faces):
        degree = len(face)
        for corner, vertex in enumerate(face):
            following = face[(corner + 1) % degree]
            preceding = face[(corner - 1) % degree]
            edge_next = (min(vertex, following), max(vertex, following))
            edge_previous = (min(preceding, vertex), max(preceding, vertex))
            output.extend((float(vertex), float(vertex_count + edge_rank[edge_next]),
                           float(face_offset + face_index),
                           float(vertex_count + edge_rank[edge_previous])))
    return output


def expected_output(values: Sequence[float] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None or type(output_is_null) is not bool:
        return -1, []
    coordinates, faces, edge_faces = parsed
    result = _subdivide(coordinates, faces, edge_faces)
    if output_is_null:
        return -2, []
    if output_capacity is not None and (type(output_capacity) is not int or
                                        output_capacity < len(result)):
        return -2, []
    return len(result), result

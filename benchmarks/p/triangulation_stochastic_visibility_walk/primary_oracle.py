"""Reference implementation for the bounded stochastic visibility walk."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 3
MAX_VERTICES = 6
MAX_BOUNDARY_VERTICES = 6
MAX_FACES = 7
MAX_STEP_CAP = 12
MAX_CHOICE_COUNT = 12
COORDINATE_BOUND = 200
MAX_VALID_INPUT_LENGTH = 56
MAX_PARSEABLE_INPUT_LENGTH = 57
STATUS_LOCATED = 0
STATUS_TAPE_EXHAUSTED = 1
STATUS_STEP_CAP = 2


def orient(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _edge_key(a: int, b: int) -> tuple[int, int]:
    return (a, b) if a < b else (b, a)


def _on_segment(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
    return (orient(a, b, p) == 0
            and min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _segments_intersect(a: tuple[int, int], b: tuple[int, int],
                        c: tuple[int, int], d: tuple[int, int]) -> bool:
    o1, o2 = orient(a, b, c), orient(a, b, d)
    o3, o4 = orient(c, d, a), orient(c, d, b)
    if ((o1 == 0 and _on_segment(a, b, c)) or (o2 == 0 and _on_segment(a, b, d))
            or (o3 == 0 and _on_segment(c, d, a)) or (o4 == 0 and _on_segment(c, d, b))):
        return True
    return ((o1 < 0 < o2 or o2 < 0 < o1)
            and (o3 < 0 < o4 or o4 < 0 < o3))


def parse_frame(values: Sequence[int]) -> dict | None:
    """Validate a frame and return bounded geometry plus its edge-neighbor table."""
    if not isinstance(values, Sequence) or len(values) < 8 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None

    vertex_count, boundary_count, face_count, start_face = values[:4]
    query_x, query_y, step_cap, choice_count = values[4:8]
    if not MIN_VERTICES <= vertex_count <= MAX_VERTICES:
        return None
    if not 3 <= boundary_count <= vertex_count:
        return None
    if face_count != 2 * vertex_count - boundary_count - 2 or not 1 <= face_count <= MAX_FACES:
        return None
    if not 0 <= start_face < face_count:
        return None
    if not 0 <= step_cap <= MAX_STEP_CAP or not 0 <= choice_count <= MAX_CHOICE_COUNT:
        return None
    if not -COORDINATE_BOUND <= query_x <= COORDINATE_BOUND:
        return None
    if not -COORDINATE_BOUND <= query_y <= COORDINATE_BOUND:
        return None
    expected_length = 8 + 2 * vertex_count + boundary_count + 3 * face_count + choice_count
    if len(values) != expected_length:
        return None

    cursor = 8
    points = [(values[cursor + 2 * i], values[cursor + 2 * i + 1])
              for i in range(vertex_count)]
    cursor += 2 * vertex_count
    if any(not -COORDINATE_BOUND <= coordinate <= COORDINATE_BOUND
           for point in points for coordinate in point):
        return None
    if len(set(points)) != vertex_count:
        return None

    boundary = list(values[cursor:cursor + boundary_count])
    cursor += boundary_count
    if (len(set(boundary)) != boundary_count
            or any(not 0 <= vertex < vertex_count for vertex in boundary)):
        return None
    boundary_edges = {
        _edge_key(boundary[index], boundary[(index + 1) % boundary_count])
        for index in range(boundary_count)
    }
    if len(boundary_edges) != boundary_count:
        return None
    for index, first in enumerate(boundary):
        second = boundary[(index + 1) % boundary_count]
        for other in boundary:
            if other != first and other != second and orient(points[first], points[second], points[other]) <= 0:
                return None
    boundary_set = set(boundary)
    for vertex in range(vertex_count):
        if vertex in boundary_set:
            continue
        if any(orient(points[boundary[index]], points[boundary[(index + 1) % boundary_count]],
                      points[vertex]) <= 0 for index in range(boundary_count)):
            return None

    faces: list[tuple[int, int, int]] = []
    face_keys: set[tuple[int, int, int]] = set()
    edge_uses: dict[tuple[int, int], list[tuple[int, int]]] = {}
    used_vertices: set[int] = set()
    area_sum = 0
    for face_id in range(face_count):
        a, b, c = values[cursor:cursor + 3]
        cursor += 3
        face = (a, b, c)
        if any(not 0 <= vertex < vertex_count for vertex in face):
            return None
        if len(set(face)) != 3 or orient(points[a], points[b], points[c]) <= 0:
            return None
        face_key = tuple(sorted(face))
        if face_key in face_keys:
            return None
        face_keys.add(face_key)
        faces.append(face)
        used_vertices.update(face)
        area_sum += orient(points[a], points[b], points[c])
        for local_edge, (u, v) in enumerate(((a, b), (b, c), (c, a))):
            edge_uses.setdefault(_edge_key(u, v), []).append((face_id, local_edge))
    if used_vertices != set(range(vertex_count)):
        return None

    unique_edges = list(edge_uses)
    for u, v in unique_edges:
        for vertex in range(vertex_count):
            if vertex != u and vertex != v and _on_segment(points[u], points[v], points[vertex]):
                return None
    for edge_index, (u, v) in enumerate(unique_edges):
        for c, d in unique_edges[edge_index + 1:]:
            if len({u, v, c, d}) == 4 and _segments_intersect(points[u], points[v], points[c], points[d]):
                return None

    polygon_area = sum(
        points[boundary[index]][0] * points[boundary[(index + 1) % boundary_count]][1]
        - points[boundary[index]][1] * points[boundary[(index + 1) % boundary_count]][0]
        for index in range(boundary_count)
    )
    if polygon_area <= 0 or area_sum != polygon_area:
        return None
    if set(edge_uses) & boundary_edges != boundary_edges:
        return None

    neighbors = [[-1, -1, -1] for _ in range(face_count)]
    for edge, uses in edge_uses.items():
        expected_uses = 1 if edge in boundary_edges else 2
        if len(uses) != expected_uses:
            return None
        if len(uses) == 2:
            (face_a, edge_a), (face_b, edge_b) = uses
            u_a, v_a = faces[face_a][edge_a], faces[face_a][(edge_a + 1) % 3]
            u_b, v_b = faces[face_b][edge_b], faces[face_b][(edge_b + 1) % 3]
            if u_a != v_b or v_a != u_b:
                return None
            neighbors[face_a][edge_a] = face_b
            neighbors[face_b][edge_b] = face_a

    if any(orient(points[boundary[index]], points[boundary[(index + 1) % boundary_count]],
                  (query_x, query_y)) <= 0 for index in range(boundary_count)):
        return None
    target_faces = [
        face_id for face_id, (a, b, c) in enumerate(faces)
        if (orient(points[a], points[b], (query_x, query_y)) > 0
            and orient(points[b], points[c], (query_x, query_y)) > 0
            and orient(points[c], points[a], (query_x, query_y)) > 0)
    ]
    if len(target_faces) != 1:
        return None

    choices = list(values[cursor:cursor + choice_count])
    if any(choice not in (0, 1) for choice in choices):
        return None
    return {
        "points": points,
        "boundary": boundary,
        "faces": faces,
        "neighbors": neighbors,
        "start_face": start_face,
        "query": (query_x, query_y),
        "step_cap": step_cap,
        "choices": choices,
        "target_face": target_faces[0],
    }


def _pack_trace(path_code: int, edge_tests: int, status: int) -> int:
    return (path_code * 40 + edge_tests) * 3 + status


def expected_result(values: Sequence[int]) -> int:
    frame = parse_frame(values)
    if frame is None:
        return -1

    points = frame["points"]
    faces = frame["faces"]
    neighbors = frame["neighbors"]
    query = frame["query"]
    choices = frame["choices"]
    face_id = frame["start_face"]
    path_code = face_id + 1
    steps = 0
    edge_tests = 0
    choice_index = 0

    while True:
        a, b, c = faces[face_id]
        separating_edges = []
        for edge_id, (u, v) in enumerate(((a, b), (b, c), (c, a))):
            edge_tests += 1
            if orient(points[u], points[v], query) < 0:
                separating_edges.append(edge_id)
        if not separating_edges:
            return _pack_trace(path_code, edge_tests, STATUS_LOCATED)
        if steps == frame["step_cap"]:
            return _pack_trace(path_code, edge_tests, STATUS_STEP_CAP)
        if len(separating_edges) == 1:
            edge_id = separating_edges[0]
        elif len(separating_edges) == 2:
            if choice_index == len(choices):
                return _pack_trace(path_code, edge_tests, STATUS_TAPE_EXHAUSTED)
            edge_id = separating_edges[choices[choice_index]]
            choice_index += 1
        else:
            return -1
        next_face = neighbors[face_id][edge_id]
        if next_face < 0:
            return -1
        face_id = next_face
        steps += 1
        path_code = path_code * 9 + face_id + 1

"""Independent geometry and transition-table oracle for the bounded walk."""

from __future__ import annotations

from collections.abc import Sequence


def _orient(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _edge_key(a: int, b: int) -> tuple[int, int]:
    return (a, b) if a < b else (b, a)


def _on_segment(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
    return (_orient(a, b, p) == 0
            and min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _intersects(a: tuple[int, int], b: tuple[int, int],
                c: tuple[int, int], d: tuple[int, int]) -> bool:
    o1, o2 = _orient(a, b, c), _orient(a, b, d)
    o3, o4 = _orient(c, d, a), _orient(c, d, b)
    if ((o1 == 0 and _on_segment(a, b, c))
            or (o2 == 0 and _on_segment(a, b, d))
            or (o3 == 0 and _on_segment(c, d, a))
            or (o4 == 0 and _on_segment(c, d, b))):
        return True
    return ((o1 < 0 < o2 or o2 < 0 < o1)
            and (o3 < 0 < o4 or o4 < 0 < o3))


def _validated_geometry(values: Sequence[int]) -> dict | None:
    if not isinstance(values, Sequence) or len(values) < 8 or len(values) > 57:
        return None
    if any(type(value) is not int for value in values):
        return None
    vertex_count, boundary_count, face_count, start_face = values[:4]
    query_x, query_y, step_cap, choice_count = values[4:8]
    if (not 3 <= vertex_count <= 6 or not 3 <= boundary_count <= vertex_count
            or face_count != 2 * vertex_count - boundary_count - 2
            or not 1 <= face_count <= 7 or not 0 <= start_face < face_count
            or not 0 <= step_cap <= 12 or not 0 <= choice_count <= 12
            or not -200 <= query_x <= 200 or not -200 <= query_y <= 200):
        return None
    if len(values) != 8 + 2 * vertex_count + boundary_count + 3 * face_count + choice_count:
        return None

    offset = 8
    points = [(values[offset + 2 * i], values[offset + 2 * i + 1])
              for i in range(vertex_count)]
    offset += 2 * vertex_count
    if (any(not -200 <= coordinate <= 200 for point in points for coordinate in point)
            or len(set(points)) != vertex_count):
        return None

    boundary = list(values[offset:offset + boundary_count])
    offset += boundary_count
    if (len(set(boundary)) != boundary_count
            or any(not 0 <= vertex < vertex_count for vertex in boundary)):
        return None
    boundary_edges = {_edge_key(boundary[i], boundary[(i + 1) % boundary_count])
                      for i in range(boundary_count)}
    if len(boundary_edges) != boundary_count:
        return None
    for i, a in enumerate(boundary):
        b = boundary[(i + 1) % boundary_count]
        if any(_orient(points[a], points[b], points[c]) <= 0
               for c in boundary if c != a and c != b):
            return None
    boundary_vertices = set(boundary)
    for vertex in range(vertex_count):
        if vertex not in boundary_vertices and any(
                _orient(points[boundary[i]], points[boundary[(i + 1) % boundary_count]],
                        points[vertex]) <= 0 for i in range(boundary_count)):
            return None

    faces: list[tuple[int, int, int]] = []
    face_sets: set[tuple[int, int, int]] = set()
    edge_owners: dict[tuple[int, int], list[tuple[int, int, int]]] = {}
    used_vertices: set[int] = set()
    triangle_area = 0
    for face_id in range(face_count):
        face = tuple(values[offset:offset + 3])
        offset += 3
        if (len(face) != 3 or any(not 0 <= vertex < vertex_count for vertex in face)
                or len(set(face)) != 3):
            return None
        a, b, c = face
        if _orient(points[a], points[b], points[c]) <= 0:
            return None
        canonical = tuple(sorted(face))
        if canonical in face_sets:
            return None
        face_sets.add(canonical)
        faces.append(face)
        used_vertices.update(face)
        triangle_area += _orient(points[a], points[b], points[c])
        for u, v in ((a, b), (b, c), (c, a)):
            edge_owners.setdefault(_edge_key(u, v), []).append((face_id, u, v))
    if used_vertices != set(range(vertex_count)):
        return None

    edge_keys = list(edge_owners)
    for edge_index, (u, v) in enumerate(edge_keys):
        for vertex in range(vertex_count):
            if vertex != u and vertex != v and _on_segment(points[u], points[v], points[vertex]):
                return None
        for c, d in edge_keys[edge_index + 1:]:
            if len({u, v, c, d}) == 4 and _intersects(points[u], points[v], points[c], points[d]):
                return None

    polygon_area = sum(
        points[boundary[i]][0] * points[boundary[(i + 1) % boundary_count]][1]
        - points[boundary[i]][1] * points[boundary[(i + 1) % boundary_count]][0]
        for i in range(boundary_count)
    )
    if polygon_area <= 0 or polygon_area != triangle_area:
        return None
    if not boundary_edges <= set(edge_owners):
        return None
    for edge, owners in edge_owners.items():
        expected_owners = 1 if edge in boundary_edges else 2
        if len(owners) != expected_owners:
            return None
        if len(owners) == 2 and (owners[0][1] != owners[1][2]
                                 or owners[0][2] != owners[1][1]):
            return None

    query = (query_x, query_y)
    if any(_orient(points[boundary[i]], points[boundary[(i + 1) % boundary_count]], query) <= 0
           for i in range(boundary_count)):
        return None
    containing_faces = []
    for face_id, (a, b, c) in enumerate(faces):
        if (_orient(points[a], points[b], query) > 0
                and _orient(points[b], points[c], query) > 0
                and _orient(points[c], points[a], query) > 0):
            containing_faces.append(face_id)
    if len(containing_faces) != 1:
        return None
    choices = list(values[offset:offset + choice_count])
    if any(choice not in (0, 1) for choice in choices):
        return None
    return {"points": points, "faces": faces, "edge_owners": edge_owners,
            "query": query, "target_face": containing_faces[0],
            "start_face": start_face, "step_cap": step_cap, "choices": choices}


def expected_result(values: Sequence[int]) -> int:
    geometry = _validated_geometry(values)
    if geometry is None:
        return -1

    # Build successor lists by scanning the edge-owner relation, rather than
    # using the primary reference's stored local-neighbor matrix.
    points = geometry["points"]
    faces = geometry["faces"]
    query = geometry["query"]
    successors: list[tuple[int, ...]] = []
    for face_id, (a, b, c) in enumerate(faces):
        destinations = []
        for u, v in ((a, b), (b, c), (c, a)):
            if _orient(points[u], points[v], query) < 0:
                owners = geometry["edge_owners"][_edge_key(u, v)]
                if len(owners) != 2:
                    return -1
                destinations.append(owners[0][0] if owners[1][0] == face_id else owners[1][0])
        successors.append(tuple(destinations))

    face_id = geometry["start_face"]
    trace = face_id + 1
    predicate_count = steps = choice_index = 0
    while True:
        predicate_count += 3
        options = successors[face_id]
        if not options:
            status = 0
            break
        if steps == geometry["step_cap"]:
            status = 2
            break
        if len(options) == 1:
            next_face = options[0]
        elif len(options) == 2:
            if choice_index == len(geometry["choices"]):
                status = 1
                break
            next_face = options[geometry["choices"][choice_index]]
            choice_index += 1
        else:
            return -1
        face_id = next_face
        trace = trace * 9 + face_id + 1
        steps += 1
    return (trace * 40 + predicate_count) * 3 + status

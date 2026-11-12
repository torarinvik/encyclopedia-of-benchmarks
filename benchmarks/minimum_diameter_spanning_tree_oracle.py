"""Clean-room minimum-diameter spanning-tree oracle and bounded certificate checker."""

from itertools import combinations
import struct

MAX_N = 8
MAX_M = 20
MAX_EDGE_WEIGHT = 9
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_N
_INF = 1 << 60


def _parse(values, input_length=None):
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int
            or input_length != len(values)
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or len(values) < 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    if len(values) != 2 + 3 * m:
        return None
    edges = []
    for offset in range(2, len(values), 3):
        u, v, weight = values[offset:offset + 3]
        if not (0 <= u < n and 0 <= v < n and 0 <= weight <= MAX_EDGE_WEIGHT):
            return None
        edges.append((u, v, weight))

    distance = [[_INF] * n for _ in range(n)]
    for vertex in range(n):
        distance[vertex][vertex] = 0
    for u, v, weight in edges:
        if u != v and weight < distance[u][v]:
            distance[u][v] = distance[v][u] = weight
    for middle in range(n):
        for left in range(n):
            through = distance[left][middle]
            if through == _INF:
                continue
            for right in range(n):
                candidate = through + distance[middle][right]
                if candidate < distance[left][right]:
                    distance[left][right] = candidate
    if any(distance[0][vertex] == _INF for vertex in range(n)):
        return None
    return n, edges, distance


def _center_tree(n, edges, center_kind, center_root, center_x2, center_edge):
    distance = [_INF] * n
    parent_edge = [-1] * n
    if center_kind == 0:
        distance[center_root] = 0
    else:
        u, v, weight = edges[center_edge]
        if u > v:
            u, v = v, u
        distance[u] = center_x2
        distance[v] = 2 * weight - center_x2

    settled = [False] * n
    for _ in range(n):
        current = -1
        for vertex in range(n):
            if (not settled[vertex]
                    and (current == -1 or distance[vertex] < distance[current])):
                current = vertex
        if current == -1 or distance[current] == _INF:
            return None
        settled[current] = True
        for edge_id, (left, right, weight) in enumerate(edges):
            if left == right:
                continue
            if current == left:
                neighbor = right
            elif current == right:
                neighbor = left
            else:
                continue
            candidate = distance[current] + 2 * weight
            if not settled[neighbor] and candidate < distance[neighbor]:
                distance[neighbor] = candidate
                parent_edge[neighbor] = edge_id

    selected = [edge_id for edge_id in parent_edge if edge_id >= 0]
    if len(selected) < n - 1 and center_kind == 1:
        u, v, _ = edges[center_edge]
        if u != v and parent_edge[u] == -1 and parent_edge[v] == -1:
            selected.append(center_edge)
    if len(selected) != n - 1:
        return None
    selected.sort()
    return selected


def _tree_diameter(n, edges, selected):
    graph = [[] for _ in range(n)]
    for edge_id in selected:
        u, v, weight = edges[edge_id]
        graph[u].append((v, weight))
        graph[v].append((u, weight))
    diameter = 0
    for source in range(n):
        stack = [(source, -1, 0)]
        while stack:
            vertex, parent, distance = stack.pop()
            diameter = max(diameter, distance)
            for neighbor, weight in graph[vertex]:
                if neighbor != parent:
                    stack.append((neighbor, vertex, distance + weight))
    return diameter


def _optimal_witness(parsed):
    n, edges, graph_distance = parsed
    best_radius2 = _INF
    best = None

    # A center at a graph vertex is the first candidate at that location.
    for root in range(n):
        radius2 = 2 * max(graph_distance[root])
        if radius2 < best_radius2:
            best_radius2 = radius2
            best = (0, root, 0, -1)

    # On an edge, doubled coordinates keep half-integral centers exact.
    # The bounded profile has weights at most nine, so scanning each doubled
    # coordinate is small and includes every possible metric center.
    for edge_id, (left, right, weight) in enumerate(edges):
        if left == right:
            continue
        u, v = sorted((left, right))
        for x2 in range(2 * weight + 1):
            radius2 = max(
                min(2 * graph_distance[u][vertex] + x2,
                    2 * graph_distance[v][vertex] + 2 * weight - x2)
                for vertex in range(n)
            )
            if radius2 < best_radius2:
                best_radius2 = radius2
                best = (1, u, x2, edge_id)

    selected = _center_tree(n, edges, *best)
    if selected is None:
        return None
    return _tree_diameter(n, edges, selected), selected


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(status, bytes)`` for ``[N,M,(u,v,w)...]``."""
    if input_is_null:
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    witness = _optimal_witness(parsed)
    if witness is None:
        return -1, b""
    diameter, selected = witness
    payload = b"".join(struct.pack("<q", value)
                       for value in (diameter, *selected))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < len(payload):
        return -2, b""
    return len(payload), payload


def validate_output(values, payload):
    """Independently check an optimal tree by enumerating all bounded witnesses."""
    parsed = _parse(values)
    if parsed is None or not isinstance(payload, (bytes, bytearray)):
        return False
    n, edges, _ = parsed
    if len(payload) != 8 * n:
        return False
    words = [struct.unpack_from("<q", payload, offset)[0]
             for offset in range(0, len(payload), 8)]
    reported_diameter, selected = words[0], words[1:]
    if (reported_diameter < 0 or len(selected) != n - 1
            or any(not 0 <= edge_id < len(edges) for edge_id in selected)
            or len(set(selected)) != len(selected)):
        return False

    def tree_diameter(edge_ids):
        parent = list(range(n))

        def find(vertex):
            while parent[vertex] != vertex:
                parent[vertex] = parent[parent[vertex]]
                vertex = parent[vertex]
            return vertex

        graph = [[] for _ in range(n)]
        for edge_id in edge_ids:
            u, v, weight = edges[edge_id]
            root_u, root_v = find(u), find(v)
            if root_u == root_v:
                return None
            parent[root_u] = root_v
            graph[u].append((v, weight))
            graph[v].append((u, weight))
        if len({find(vertex) for vertex in range(n)}) != 1:
            return None
        diameter = 0
        for source in range(n):
            stack = [(source, -1, 0)]
            while stack:
                vertex, previous, distance = stack.pop()
                diameter = max(diameter, distance)
                for neighbor, weight in graph[vertex]:
                    if neighbor != previous:
                        stack.append((neighbor, vertex, distance + weight))
        return diameter

    actual = tree_diameter(selected)
    if actual is None or actual != reported_diameter:
        return False

    optimum = _INF
    for edge_ids in combinations(range(len(edges)), n - 1):
        candidate = tree_diameter(edge_ids)
        if candidate is not None:
            optimum = min(optimum, candidate)
    return reported_diameter == optimum

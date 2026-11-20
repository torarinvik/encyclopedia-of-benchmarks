"""Independent bounded Sp Cons reference using Boolean matrices and Floyd–Warshall."""
from __future__ import annotations

from collections.abc import Sequence

MAX_N = 20
MAX_M = MAX_N * (MAX_N - 1) // 2
MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * MAX_M + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = MAX_M
WORKSPACE_BYTES = 65_536
INF = 1_000_000


def _read(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    edge_index: dict[tuple[int, int], int] = {}
    for edge_id in range(m):
        u, v = values[2 + 2 * edge_id], values[3 + 2 * edge_id]
        if not 0 <= u < v < n or (u, v) in edge_index:
            return None
        edges.append((u, v))
        edge_index[(u, v)] = edge_id
    return n, edges, edge_index


def _matrix(n: int, edges: list[tuple[int, int]]) -> list[list[bool]]:
    adjacent = [[False] * n for _ in range(n)]
    for u, v in edges:
        adjacent[u][v] = adjacent[v][u] = True
    return adjacent


def _floyd(n: int, adjacent: list[list[bool]], allowed: set[int] | None = None):
    distance = [[0 if u == v else INF for v in range(n)] for u in range(n)]
    for u in range(n):
        for v in range(n):
            if adjacent[u][v] and (allowed is None or u in allowed and v in allowed):
                distance[u][v] = 1
    for via in range(n):
        for left in range(n):
            for right in range(n):
                candidate = distance[left][via] + distance[via][right]
                if candidate < distance[left][right]:
                    distance[left][right] = candidate
    return distance


def _lex_path(source: int, target: int, adjacent: list[list[bool]],
              distance: list[list[int]]) -> list[int]:
    # Greedy lowest-next-vertex reconstruction is lexicographic because each
    # step preserves the exact remaining shortest-path distance.
    if distance[source][target] >= INF:
        return []
    path = [source]
    current = source
    while current != target:
        remaining = distance[current][target]
        next_vertex = next((v for v in range(len(adjacent))
                            if adjacent[current][v]
                            and distance[v][target] == remaining - 1), None)
        if next_vertex is None:
            return []
        path.append(next_vertex)
        current = next_vertex
    return path


def _tree_edges(root: int, members: set[int], adjacent: list[list[bool]],
                edge_index: dict[tuple[int, int], int]) -> tuple[set[int], int]:
    distance = _floyd(len(adjacent), adjacent, members)
    result: set[int] = set()
    radius = 0
    for vertex in sorted(members):
        path = _lex_path(root, vertex, adjacent, distance)
        radius = max(radius, len(path) - 1)
        for a, b in zip(path, path[1:]):
            result.add(edge_index[(min(a, b), max(a, b))])
    return result, radius


def _connector(left: set[int], right: set[int], adjacent: list[list[bool]],
               edge_index: dict[tuple[int, int], int],
               distance: list[list[int]]) -> set[int]:
    best_key: tuple[int, tuple[int, ...]] | None = None
    best_path: list[int] = []
    for source in sorted(left):
        for target in sorted(right):
            path = _lex_path(source, target, adjacent, distance)
            if not path:
                continue
            key = (distance[source][target], tuple(path))
            if best_key is None or key < best_key:
                best_key, best_path = key, path
    return {edge_index[(min(a, b), max(a, b))]
            for a, b in zip(best_path, best_path[1:])}


def _separation(left: set[int], right: set[int], distance: list[list[int]]) -> int:
    return min((distance[u][v] for u in left for v in right), default=INF)


def _down_part(n: int, adjacent: list[list[bool]], edge_index: dict[tuple[int, int], int]):
    unused = [True] * n
    ground: list[dict] = []
    chosen: set[int] = set()
    while any(unused):
        root = next(vertex for vertex in range(n) if unused[vertex])
        members = {root}
        while True:
            shell = members | {v for u in members for v in range(n)
                               if adjacent[u][v] and unused[v]}
            if shell == members or len(shell) ** 4 < n * len(members) ** 4:
                break
            members = shell
        shell = members | {v for u in members for v in range(n)
                           if adjacent[u][v] and unused[v]}
        cluster_tree, radius = _tree_edges(root, members, adjacent, edge_index)
        shell_tree, _ = _tree_edges(root, shell, adjacent, edge_index)
        chosen.update(shell_tree)
        ground.append({"center": root, "members": members, "tree": cluster_tree,
                       "radius": radius})
        for vertex in members:
            unused[vertex] = False
    return ground, chosen


def _supercluster(adjacent: list[list[bool]], edge_index: dict[tuple[int, int], int],
                  distance: list[list[int]], clusters: list[dict], sigma: int, delta: int):
    remaining = list(range(len(clusters)))
    output: list[dict] = []
    chosen: set[int] = set()
    while True:
        qualifying: list[tuple[tuple[int, tuple[int, ...]], int, list[int]]] = []
        for center_id in remaining:
            center = clusters[center_id]
            close = [other_id for other_id in remaining
                     if _separation(center["members"], clusters[other_id]["members"], distance)
                     <= delta]
            order_key = (center["center"], tuple(sorted(center["members"])))
            if len(close) >= sigma:
                qualifying.append((order_key, center_id, close))
        if not qualifying:
            break
        _, center_id, close = min(qualifying, key=lambda item: item[0])
        center = clusters[center_id]
        close.sort(key=lambda i: (clusters[i]["center"],
                                  tuple(sorted(clusters[i]["members"]))))
        members: set[int] = set()
        tree: set[int] = set()
        for other_id in close:
            other = clusters[other_id]
            members.update(other["members"])
            tree.update(other["tree"])
            if other_id != center_id:
                tree.update(_connector(center["members"], other["members"],
                                       adjacent, edge_index, distance))
        chosen.update(tree)
        output.append({"center": center["center"], "members": members,
                       "tree": tree, "radius": 0})
        removed = set(close)
        remaining = [i for i in remaining if i not in removed]

    for pos, left_id in enumerate(remaining):
        for right_id in remaining[pos + 1:]:
            left, right = clusters[left_id], clusters[right_id]
            if _separation(left["members"], right["members"], distance) <= delta:
                chosen.update(_connector(left["members"], right["members"],
                                         adjacent, edge_index, distance))
    return output, chosen


def _construct(n: int, edges: list[tuple[int, int]], edge_index: dict[tuple[int, int], int]):
    adjacent = _matrix(n, edges)
    distance = _floyd(n, adjacent)
    ground, chosen = _down_part(n, adjacent, edge_index)
    radius_one = [cluster for cluster in ground if cluster["radius"] == 1]
    sigma = next(value for value in range(1, n + 1) if value ** 4 >= n)
    superclusters, additions = _supercluster(
        adjacent, edge_index, distance, radius_one, sigma, 16)
    chosen.update(additions)
    final_clusters = superclusters + [cluster for cluster in ground
                                      if cluster["radius"] in (2, 3)]
    final_clusters.sort(key=lambda cluster: (cluster["center"],
                                             tuple(sorted(cluster["members"]))))
    for left_id, left in enumerate(final_clusters):
        for right in final_clusters[left_id + 1:]:
            if _separation(left["members"], right["members"], distance) <= 128:
                chosen.update(_connector(left["members"], right["members"],
                                         adjacent, edge_index, distance))
    return [int(edge_id in chosen) for edge_id in range(len(edges))]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    n, edges, edge_index = parsed
    selected = _construct(n, edges, edge_index)
    if output_is_null or capacity is not None and capacity < len(edges):
        return -2, b""
    payload = bytes(selected)
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]

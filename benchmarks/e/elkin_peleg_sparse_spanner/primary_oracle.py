"""Bounded canonical profile of Elkin–Peleg Sp Cons, using BFS adjacency lists."""
from __future__ import annotations

from collections.abc import Sequence

MAX_N = 20
MAX_M = MAX_N * (MAX_N - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = MAX_M
WORKSPACE_BYTES = 65_536
INF = 1_000
DELTA_LEVEL_1 = 16  # SC is called with 2 * Υ^(1/2), where Υ=64.
DELTA_FINAL = 128    # Final pair pass uses 2 * Υ.


def _parse(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    edge_index: dict[tuple[int, int], int] = {}
    for edge_id in range(m):
        u, v = values[2 + 2 * edge_id:4 + 2 * edge_id]
        if not 0 <= u < v < n or (u, v) in edge_index:
            return None
        edges.append((u, v))
        edge_index[(u, v)] = edge_id
    return n, edges, edge_index


def _adjacency(n: int, edges: list[tuple[int, int]]) -> list[list[int]]:
    graph = [[] for _ in range(n)]
    for u, v in edges:
        graph[u].append(v)
        graph[v].append(u)
    # FIFO layers plus ascending neighbors make first discovery the
    # lexicographically smallest vertex sequence among shortest paths.
    for neighbors in graph:
        neighbors.sort()
    return graph


def _bfs_tree(adjacency: list[list[int]], edge_index: dict[tuple[int, int], int],
              allowed: set[int], root: int) -> tuple[set[int], list[int]]:
    distance = [INF] * len(adjacency)
    parent = [-1] * len(adjacency)
    distance[root] = 0
    queue = [root]
    for vertex in queue:
        for neighbor in adjacency[vertex]:
            if neighbor in allowed and distance[neighbor] == INF:
                distance[neighbor] = distance[vertex] + 1
                parent[neighbor] = vertex
                queue.append(neighbor)
    tree: set[int] = set()
    for vertex in allowed:
        if vertex != root:
            tree.add(edge_index[(min(vertex, parent[vertex]), max(vertex, parent[vertex]))])
    return tree, distance


def _all_distances(adjacency: list[list[int]]) -> list[list[int]]:
    rows: list[list[int]] = []
    for source in range(len(adjacency)):
        distance = [INF] * len(adjacency)
        distance[source] = 0
        queue = [source]
        for vertex in queue:
            for neighbor in adjacency[vertex]:
                if distance[neighbor] == INF:
                    distance[neighbor] = distance[vertex] + 1
                    queue.append(neighbor)
        rows.append(distance)
    return rows


def _set_distance(left: set[int], right: set[int], distances: list[list[int]]) -> int:
    return min((distances[u][v] for u in left for v in right), default=INF)


def _connector(adjacency: list[list[int]], edge_index: dict[tuple[int, int], int],
               left: set[int], right: set[int]) -> set[int]:
    """Return edges of the shortest, then lexicographically first, left-to-right path."""
    best_key: tuple[int, tuple[int, ...]] | None = None
    best_path: list[int] = []
    n = len(adjacency)
    for source in sorted(left):
        distance = [INF] * n
        parent = [-1] * n
        distance[source] = 0
        queue = [source]
        # The same FIFO/ascending-neighbor order fixes each target's canonical
        # shortest path; compare candidates in source/target vertex order too.
        for vertex in queue:
            for neighbor in adjacency[vertex]:
                if distance[neighbor] == INF:
                    distance[neighbor] = distance[vertex] + 1
                    parent[neighbor] = vertex
                    queue.append(neighbor)
        for target in sorted(right):
            if distance[target] == INF:
                continue
            path = [target]
            while path[-1] != source:
                path.append(parent[path[-1]])
            path.reverse()
            key = (distance[target], tuple(path))
            if best_key is None or key < best_key:
                best_key, best_path = key, path
    result: set[int] = set()
    for a, b in zip(best_path, best_path[1:]):
        result.add(edge_index[(min(a, b), max(a, b))])
    return result


def _cluster(center: int, members: set[int], tree: set[int], radius: int) -> dict:
    return {"center": center, "members": members, "tree": tree, "radius": radius}


def _down_part(n: int, adjacency: list[list[int]], edge_index: dict[tuple[int, int], int]):
    uncovered = set(range(n))
    ground: list[dict] = []
    chosen: set[int] = set()
    while uncovered:
        root = min(uncovered)
        members = {root}
        while True:
            next_layer = {neighbor for vertex in members for neighbor in adjacency[vertex]
                          if neighbor in uncovered}
            shell = members | next_layer
            # Exact integer form of |shell| >= n^(1/4) * |members|.
            if shell == members or len(shell) ** 4 < n * len(members) ** 4:
                break
            members = shell
        shell = members | {neighbor for vertex in members for neighbor in adjacency[vertex]
                          if neighbor in uncovered}
        cluster_tree, cluster_distances = _bfs_tree(adjacency, edge_index, members, root)
        shell_tree, _ = _bfs_tree(adjacency, edge_index, shell, root)
        chosen.update(shell_tree)
        radius = max(cluster_distances[vertex] for vertex in members)
        ground.append(_cluster(root, members, cluster_tree, radius))
        uncovered.difference_update(members)
    return ground, chosen


def _supercluster(adjacency: list[list[int]], edge_index: dict[tuple[int, int], int],
                  distances: list[list[int]], clusters: list[dict], sigma: int, delta: int):
    active = set(range(len(clusters)))
    merged: list[dict] = []
    chosen: set[int] = set()
    while True:
        candidates = []
        neighborhoods: dict[int, list[int]] = {}
        for center_id in sorted(active, key=lambda i: (clusters[i]["center"],
                                                       tuple(sorted(clusters[i]["members"])) )):
            center = clusters[center_id]
            near = [other_id for other_id in sorted(
                active, key=lambda i: (clusters[i]["center"],
                                       tuple(sorted(clusters[i]["members"]))))
                    if _set_distance(center["members"], clusters[other_id]["members"], distances)
                    <= delta]
            neighborhoods[center_id] = near
            if len(near) >= sigma:
                candidates.append(center_id)
        if not candidates:
            break
        center_id = min(candidates, key=lambda i: (clusters[i]["center"],
                                                    tuple(sorted(clusters[i]["members"]))))
        center = clusters[center_id]
        near = neighborhoods[center_id]
        members: set[int] = set()
        tree: set[int] = set()
        for other_id in near:
            other = clusters[other_id]
            members.update(other["members"])
            tree.update(other["tree"])
            if other_id != center_id:
                tree.update(_connector(adjacency, edge_index, center["members"], other["members"]))
        chosen.update(tree)
        merged.append(_cluster(center["center"], members, tree, 0))
        active.difference_update(near)

    remaining = sorted(active, key=lambda i: (clusters[i]["center"],
                                               tuple(sorted(clusters[i]["members"]))))
    for offset, left_id in enumerate(remaining):
        for right_id in remaining[offset + 1:]:
            left, right = clusters[left_id], clusters[right_id]
            if _set_distance(left["members"], right["members"], distances) <= delta:
                chosen.update(_connector(adjacency, edge_index, left["members"], right["members"]))
    return merged, chosen


def _construct(n: int, edges: list[tuple[int, int]], edge_index: dict[tuple[int, int], int]) -> list[int]:
    adjacency = _adjacency(n, edges)
    distances = _all_distances(adjacency)
    ground, chosen = _down_part(n, adjacency, edge_index)

    # κ=4, J=2: t₁=3/8, t₂=1/8. The first radius band contains radius 1.
    radius_one = [cluster for cluster in ground if cluster["radius"] == 1]
    sigma = 1
    while sigma ** 4 < n:
        sigma += 1
    superclusters, extra = _supercluster(
        adjacency, edge_index, distances, radius_one, sigma, DELTA_LEVEL_1)
    chosen.update(extra)

    # The final band [κt₁, κ) contains integer radii 2 and 3.
    final_clusters = superclusters + [cluster for cluster in ground
                                      if cluster["radius"] in (2, 3)]
    final_clusters.sort(key=lambda cluster: (cluster["center"],
                                             tuple(sorted(cluster["members"]))))
    for left_id, left in enumerate(final_clusters):
        for right in final_clusters[left_id + 1:]:
            if _set_distance(left["members"], right["members"], distances) <= DELTA_FINAL:
                chosen.update(_connector(adjacency, edge_index,
                                         left["members"], right["members"]))
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
    parsed = _parse(values)
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

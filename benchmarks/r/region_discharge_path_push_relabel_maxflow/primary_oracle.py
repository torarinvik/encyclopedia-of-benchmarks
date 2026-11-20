"""Bounded sequential S-ARD maximum-flow reference.

This implements the paper's region-distance labels and staged augmenting-path
discharge, using deterministic breadth-first path selection within each region.
"""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

INVALID_RESULT = -1
MIN_VERTICES = 4
MAX_VERTICES = 8
MAX_ARCS = 12
MAX_REGIONS = 4
MAX_CAPACITY = 7
MAX_VALID_INPUT_LENGTH = 5 + MAX_VERTICES + 3 * MAX_ARCS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_ARCS * MAX_CAPACITY


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    n, m, region_count, source, sink = values[:5]
    if (not MIN_VERTICES <= n <= MAX_VERTICES
            or not 1 <= m <= MAX_ARCS
            or not 2 <= region_count <= min(MAX_REGIONS, n - 2)
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 5 + n + 3 * m):
        return None
    regions = list(values[5:5 + n])
    for v, region in enumerate(regions):
        if v in (source, sink):
            if region != -1:
                return None
        elif not 0 <= region < region_count:
            return None
    if set(regions[v] for v in range(n) if v not in (source, sink)) != set(range(region_count)):
        return None
    arcs = []
    offset = 5 + n
    for i in range(m):
        u, v, capacity = values[offset + 3 * i:offset + 3 * i + 3]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or v == source or u == sink
                or not 0 <= capacity <= MAX_CAPACITY):
            return None
        arcs.append((u, v, capacity))
    return n, m, region_count, source, sink, regions, arcs


def _reachable(local_residual: list[list[int]], allowed: list[list[bool]],
               start: int, targets: set[int]) -> bool:
    if start in targets:
        return True
    seen = [False] * len(local_residual)
    seen[start] = True
    queue = deque([start])
    while queue:
        u = queue.popleft()
        for v in range(len(local_residual)):
            if (not seen[v] and allowed[u][v]
                    and local_residual[u][v] > 0):
                if v in targets:
                    return True
                seen[v] = True
                queue.append(v)
    return False


def _find_stage_path(local_residual: list[list[int]], allowed: list[list[bool]],
                     region_vertices: list[int], targets: set[int],
                     excess: list[int]):
    """Return a shortest residual path from any active region vertex to Tk."""
    size = len(local_residual)
    parent = [-1] * size
    queue: deque[int] = deque()
    for v in region_vertices:
        if excess[v] > 0:
            parent[v] = v
            queue.append(v)
    while queue:
        u = queue.popleft()
        for v in range(size):
            if parent[v] != -1 or not allowed[u][v] or local_residual[u][v] <= 0:
                continue
            parent[v] = u
            if v in targets:
                path = [v]
                while parent[path[-1]] != path[-1]:
                    path.append(parent[path[-1]])
                path.reverse()
                return path
            queue.append(v)
    return None


def _region_discharge(residual: list[list[int]], excess: list[int], labels: list[int],
                      flow_value: int, n: int, source: int, sink: int,
                      region_id: int, regions: list[int], boundary_by_region: list[set[int]],
                      boundary_count: int) -> int:
    region_vertices = [v for v in range(n)
                      if v not in (source, sink) and regions[v] == region_id]
    external = boundary_by_region[region_id]
    inside_or_terminal = set(region_vertices) | {source, sink}
    local_vertices = inside_or_terminal | external
    allowed = [[False] * n for _ in range(n)]
    for u in local_vertices:
        for v in local_vertices:
            allowed[u][v] = (
                (u in inside_or_terminal and v in inside_or_terminal)
                or (u in region_vertices and v in external)
                or (u in external and v in region_vertices)
            )
    local_residual = [[0] * n for _ in range(n)]
    for u in local_vertices:
        for v in local_vertices:
            if allowed[u][v] and not (u in external and v in region_vertices):
                local_residual[u][v] = residual[u][v]

    for stage in range(boundary_count + 1):
        targets = {sink}
        targets.update(v for v in external if labels[v] < stage)
        while True:
            path = _find_stage_path(local_residual, allowed, region_vertices,
                                    targets, excess)
            if path is None:
                break
            start, finish = path[0], path[-1]
            amount = excess[start]
            for u, v in zip(path, path[1:]):
                amount = min(amount, local_residual[u][v])
            for u, v in zip(path, path[1:]):
                local_residual[u][v] -= amount
                local_residual[v][u] += amount
                residual[u][v] -= amount
                residual[v][u] += amount
            excess[start] -= amount
            if finish == sink:
                flow_value += amount
            else:
                excess[finish] += amount

    for u in region_vertices:
        new_label = boundary_count
        for stage in range(boundary_count + 1):
            targets = {sink}
            targets.update(v for v in external if labels[v] < stage)
            if _reachable(local_residual, allowed, u, targets):
                new_label = stage
                break
        labels[u] = max(labels[u], new_label)
    return flow_value


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, m, region_count, source, sink, regions, arcs = parsed
    capacity = [[0] * n for _ in range(n)]
    for u, v, cap in arcs:
        capacity[u][v] += cap

    boundary: set[int] = set()
    boundary_by_region = [set() for _ in range(region_count)]
    for u, v, cap in arcs:
        if cap and regions[u] >= 0 and regions[v] >= 0 and regions[u] != regions[v]:
            boundary.update((u, v))
            boundary_by_region[regions[u]].add(v)
            boundary_by_region[regions[v]].add(u)
    boundary_count = len(boundary)
    if boundary_count < 2:
        return INVALID_RESULT

    residual = [row[:] for row in capacity]
    excess = [0] * n
    flow_value = 0
    # Init: saturate all source-outgoing arcs to create a preflow.
    for v in range(n):
        amount = residual[source][v]
        if amount:
            residual[source][v] = 0
            residual[v][source] += amount
            if v == sink:
                flow_value += amount
            else:
                excess[v] += amount
    labels = [0] * n
    labels[source] = boundary_count

    sweep_limit = 2 * boundary_count * boundary_count + 1
    for _ in range(sweep_limit):
        for region_id in range(region_count):
            flow_value = _region_discharge(
                residual, excess, labels, flow_value, n, source, sink,
                region_id, regions, boundary_by_region, boundary_count
            )
        if not any(excess[v] > 0 and labels[v] < boundary_count
                   for v in range(n) if v not in (source, sink)):
            break
    else:
        return INVALID_RESULT
    return flow_value


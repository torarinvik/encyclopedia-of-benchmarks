"""Four-sweep candidate-edge reduction followed by Kruskal's algorithm."""

from __future__ import annotations

from collections.abc import Sequence

MAX_POINTS = 31
COORD_MIN = -1000
COORD_MAX = 1000
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_POINTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 8192
MAX_RESULT = (MAX_POINTS - 1) * 4000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[tuple[int, int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_POINTS or len(values) != 1 + 2 * count:
        return None
    points = []
    xs = set()
    ys = set()
    for offset in range(1, len(values), 2):
        x, y = values[offset], values[offset + 1]
        if not COORD_MIN <= x <= COORD_MAX or not COORD_MIN <= y <= COORD_MAX:
            return None
        if x in xs or y in ys:
            return None
        xs.add(x)
        ys.add(y)
        points.append((x, y))
    return points


def _candidate_edges(points: list[tuple[int, int]]) -> list[tuple[int, int, int]]:
    """Return (weight,u,v) edges from the four octant sweeps."""
    point_count = len(points)
    transformed = list(points)
    edges: list[tuple[int, int, int]] = []

    for rotation in range(4):
        x_values = sorted(point[0] for point in transformed)
        rank_by_x = {x: rank for rank, x in enumerate(x_values)}
        point_at_rank = [0] * point_count
        for point_id, (x, _) in enumerate(transformed):
            point_at_rank[rank_by_x[x]] = point_id

        fenwick = [0] * (point_count + 1)

        def add(rank: int, delta: int) -> None:
            index = rank + 1
            while index <= point_count:
                fenwick[index] += delta
                index += index & -index

        def prefix_count(end: int) -> int:
            total = 0
            while end > 0:
                total += fenwick[end]
                end -= end & -end
            return total

        def select(k: int) -> int:
            index = 0
            step = 1 << (point_count.bit_length() - 1)
            while step:
                candidate = index + step
                if candidate <= point_count and fenwick[candidate] < k:
                    index = candidate
                    k -= fenwick[candidate]
                step >>= 1
            return index

        order = sorted(range(point_count),
                       key=lambda i: (transformed[i][0] + transformed[i][1],
                                      transformed[i][0] - transformed[i][1], i))
        for point_id in order:
            x, y = transformed[point_id]
            rank = rank_by_x[x]
            active_count = prefix_count(rank + 1)
            while active_count:
                candidate_rank = select(active_count)
                other_id = point_at_rank[candidate_rank]
                other_x, other_y = transformed[other_id]
                if x - y > other_x - other_y:
                    break
                original_x1, original_y1 = points[point_id]
                original_x2, original_y2 = points[other_id]
                weight = abs(original_x1 - original_x2) + abs(original_y1 - original_y2)
                edges.append((weight, point_id, other_id))
                add(candidate_rank, -1)
                active_count -= 1
            add(rank, 1)

        if rotation % 2 == 0:
            transformed = [(y, x) for x, y in transformed]
        else:
            transformed = [(-x, y) for x, y in transformed]
    return edges


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the Manhattan MST weight or -1 for an invalid point set."""
    points = _decode(values, input_length, input_is_null)
    if points is None:
        return -1
    count = len(points)
    if count < 2:
        return 0

    parent = list(range(count))
    sizes = [1] * count

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    total = 0
    used = 0
    for weight, left, right in sorted(_candidate_edges(points)):
        left_root = find(left)
        right_root = find(right)
        if left_root == right_root:
            continue
        if sizes[left_root] < sizes[right_root]:
            left_root, right_root = right_root, left_root
        parent[right_root] = left_root
        sizes[left_root] += sizes[right_root]
        total += weight
        used += 1
        if used == count - 1:
            return total
    return -1

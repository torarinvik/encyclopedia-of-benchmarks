"""Independent exhaustive vertex-deletion oracle for global vertex connectivity."""

import itertools

MAX_VERTICES = 10
MAX_EDGES = 45
MAX_INPUT_LENGTH = 92
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _read_simple_graph(values, input_is_null, input_length):
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(input_is_null) is not bool or (input_is_null and values)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))):
        return None
    if any(type(item) is not int or item < I64_MIN or item > I64_MAX for item in values):
        return None
    if input_is_null or len(values) < 2:
        return None
    n, m = int(values[0]), int(values[1])
    if not (0 <= n <= MAX_VERTICES and 0 <= m <= MAX_EDGES):
        return None
    if len(values) != 2 + 2*m:
        return None
    neighbors = [set() for _ in range(n)]
    for edge_index in range(m):
        left, right = values[2 + 2*edge_index:4 + 2*edge_index]
        if left < 0 or right < 0 or left >= n or right >= n:
            return None
        if left != right:
            neighbors[left].add(right)
            neighbors[right].add(left)
    return neighbors


def _component_count(neighbors, removed_mask=0):
    n = len(neighbors)
    seen = removed_mask
    count = 0
    for start in range(n):
        if seen & (1 << start):
            continue
        count += 1
        seen |= 1 << start
        queue = [start]
        for vertex in queue:
            for other in neighbors[vertex]:
                if not seen & (1 << other):
                    seen |= 1 << other
                    queue.append(other)
    return count


def expected_result(values, input_is_null=False, input_length=None):
    neighbors = _read_simple_graph(values, input_is_null, input_length)
    if neighbors is None:
        return -1
    n = len(neighbors)
    if n <= 1 or _component_count(neighbors) != 1:
        return 0
    for removed_count in range(1, n - 1):
        for removed_vertices in itertools.combinations(range(n), removed_count):
            removed_mask = sum(1 << vertex for vertex in removed_vertices)
            if _component_count(neighbors, removed_mask) > 1:
                return removed_count
    return n - 1

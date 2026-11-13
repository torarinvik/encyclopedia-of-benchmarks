"""Independent exhaustive-cut verifier for bounded directed maximum flow."""

try:
    from .isap_maxflow_oracle import (
        MAX_CAPACITY,
        MAX_EDGES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VERTICES,
    )
except ImportError:  # Direct import from the benchmarks directory.
    from isap_maxflow_oracle import (
        MAX_CAPACITY,
        MAX_EDGES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VERTICES,
    )

MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1
    n, edge_count, source, sink = values[:4]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 4 + 3 * edge_count):
        return -1
    edges = []
    for index in range(edge_count):
        u, v, capacity = values[4 + 3 * index:7 + 3 * index]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= capacity <= MAX_CAPACITY):
            return -1
        edges.append((u, v, capacity))
    best = sum(capacity for _, _, capacity in edges)
    for mask in range(1 << n):
        if not mask & (1 << source) or mask & (1 << sink):
            continue
        cut = sum(capacity for u, v, capacity in edges
                  if mask & (1 << u) and not mask & (1 << v))
        if cut < best:
            best = cut
    return best

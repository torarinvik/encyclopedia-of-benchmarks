"""Independent exhaustive-cut oracle for a bounded directed max-flow profile."""


MAX_VERTICES = 8
MAX_EDGES = 24
MAX_CAPACITY = 100
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH


def expected_result(values):
    """Return the exact minimum-cut capacity for ``[N,M,s,t,(u,v,c)*M]``."""
    if not isinstance(values, (list, tuple)) or len(values) < 4:
        return -1
    if any(type(value) is not int for value in values):
        return -1
    n, edge_count, source, sink = values[:4]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or not 1 <= source <= n or not 1 <= sink <= n or source == sink
            or len(values) != 4 + 3 * edge_count):
        return -1

    edges = []
    for edge_index in range(edge_count):
        start, end, capacity = values[4 + 3 * edge_index:7 + 3 * edge_index]
        if (not 1 <= start <= n or not 1 <= end <= n or start == end
                or not 0 <= capacity <= MAX_CAPACITY):
            return -1
        edges.append((start - 1, end - 1, capacity))

    best = sum(capacity for _, _, capacity in edges) + 1
    for side_mask in range(1 << n):
        if not (side_mask & (1 << (source - 1))):
            continue
        if side_mask & (1 << (sink - 1)):
            continue
        cut_capacity = sum(
            capacity for start, end, capacity in edges
            if (side_mask & (1 << start)) and not (side_mask & (1 << end))
        )
        best = min(best, cut_capacity)
    return best

"""Exact weighted-MWIS reduction for efficient domination in general graphs."""

MAX_VERTICES = 12
MAX_EDGES = 66
MAX_VALID_INPUT_LENGTH = 134
MAX_PARSEABLE_INPUT_LENGTH = 135
WORKSPACE_BYTES = 4096


def _parse(values):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, edge_count = values[:2]
    if not (1 <= n <= MAX_VERTICES
            and 0 <= edge_count <= n * (n - 1) // 2
            and len(values) == 2 + 2 * edge_count):
        return None
    adjacency = [0] * n
    for at in range(edge_count):
        u, v = values[2 + 2 * at:4 + 2 * at]
        if not (0 <= u < v < n) or (adjacency[u] >> v) & 1:
            return None
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u
    return n, adjacency


def _popcount(bits):
    return bits.bit_count()


def _maximum_weight_independent_set(square_adjacency, weights):
    n = len(weights)
    best = 0

    def search(remaining, current_weight):
        nonlocal best
        upper_bound = current_weight
        scan = remaining
        while scan:
            bit = scan & -scan
            vertex = bit.bit_length() - 1
            upper_bound += weights[vertex]
            scan ^= bit
        if upper_bound <= best:
            return
        if remaining == 0:
            best = current_weight
            return

        branch = -1
        branch_degree = -1
        scan = remaining
        while scan:
            bit = scan & -scan
            vertex = bit.bit_length() - 1
            degree = _popcount(square_adjacency[vertex] & remaining)
            if degree > branch_degree:
                branch = vertex
                branch_degree = degree
            scan ^= bit
        bit = 1 << branch
        search(remaining & ~bit & ~square_adjacency[branch],
               current_weight + weights[branch])
        search(remaining & ~bit, current_weight)

    search((1 << n) - 1, 0)
    return best


def expected_result(values):
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, adjacency = parsed
    square = [0] * n
    weights = [0] * n
    for vertex in range(n):
        square[vertex] = adjacency[vertex]
        scan = adjacency[vertex]
        while scan:
            bit = scan & -scan
            neighbor = bit.bit_length() - 1
            square[vertex] |= adjacency[neighbor]
            scan ^= bit
        square[vertex] &= ~(1 << vertex)
        weights[vertex] = _popcount(adjacency[vertex]) + 1
    return int(_maximum_weight_independent_set(square, weights) == n)

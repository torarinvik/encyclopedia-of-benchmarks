"""Edge-subset enumeration reference for the small fixture graph domain."""

MAX_VERTICES = 64


def _decode(values):
    if len(values) < 2 or len(values) > 6051:
        return None
    vertices, edge_count = values[0], values[1]
    if vertices < 1 or vertices > MAX_VERTICES or edge_count < 0:
        return None
    if edge_count > vertices * (vertices - 1) // 2 or len(values) != 2 + 3 * edge_count:
        return None
    edges = []
    pair_keys = set()
    for offset in range(2, len(values), 3):
        first, second, weight = values[offset:offset + 3]
        if first < 0 or first >= vertices or second < 0 or second >= vertices:
            return None
        if first == second or weight < 1 or weight > 1_000_000:
            return None
        key = (min(first, second), max(first, second))
        if key in pair_keys:
            return None
        pair_keys.add(key)
        edges.append((key[0], key[1], weight))
    return vertices, edges


def _sum_disjoint_edges(edges):
    occupied = set()
    total = 0
    for u, v, weight in edges:
        if u in occupied or v in occupied:
            return None
        occupied.add(u)
        occupied.add(v)
        total += weight
    return total


def solve(values):
    parsed = _decode(values)
    if parsed is None:
        return -2
    n, edges = parsed
    if n > 18:
        answer = _sum_disjoint_edges(edges)
        if answer is None:
            raise ValueError("independent oracle only defines the documented large sparse fixtures")
        return answer

    best = 0
    for chosen in range(1 << len(edges)):
        occupied = 0
        value = 0
        valid = True
        for index, (u, v, weight) in enumerate(edges):
            if chosen & (1 << index):
                ends = (1 << u) | (1 << v)
                if occupied & ends:
                    valid = False
                    break
                occupied |= ends
                value += weight
        if valid and value > best:
            best = value
    return best


expected_result = solve

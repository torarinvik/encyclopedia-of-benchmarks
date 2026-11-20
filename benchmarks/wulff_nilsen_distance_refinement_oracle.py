"""Primary bounded reference for Wulff--Nilsen Figure 4 refinement."""

from __future__ import annotations

INVALID_RESULT = -1
MAX_N = 8
MAX_M = MAX_N * (MAX_N - 1) // 2
K = 4
EPSILON_NUMERATOR = 1
EPSILON_DENOMINATOR = 2
ALPHA = 192
MAX_REDUCTIONS = 16
SCALE = 2 * (3 ** MAX_REDUCTIONS)
MAX_BASE_WEIGHT = 100
MAX_VALID_INPUT_LENGTH = 8 + 3 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_WORKSPACE_BYTES = 8192
MAX_RESULT_BOUND = 662_919_503_400
INF = 1 << 60


def _parse(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 8 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[:2]
    if not 2 <= n <= MAX_N or not 0 <= m <= MAX_M:
        return None
    if len(values) != 8 + 3 * m:
        return None
    masks = tuple(values[2:5])
    full = (1 << n) - 1
    if any(mask <= 0 or mask & ~full for mask in masks):
        return None
    if masks[1] & ~masks[0] or masks[2] & ~masks[1]:
        return None

    edges = []
    graph = [[] for _ in range(n)]
    previous = None
    for edge_index in range(m):
        offset = 5 + 3 * edge_index
        u, v, weight = values[offset:offset + 3]
        if (not 0 <= u < v < n or weight % SCALE != 0
                or not SCALE <= weight <= MAX_BASE_WEIGHT * SCALE):
            return None
        pair = (u, v)
        if previous is not None and pair <= previous:
            return None
        previous = pair
        edges.append((u, v, weight))
        graph[u].append((v, weight))
        graph[v].append((u, weight))

    query_offset = 5 + 3 * m
    source, target, estimate = values[query_offset:query_offset + 3]
    if (not 0 <= source < n or not 0 <= target < n or source == target
            or estimate <= 0 or estimate % SCALE != 0):
        return None
    return n, masks, edges, graph, source, target, estimate


def _all_pairs(n, edges):
    distance = [[0 if u == v else INF for v in range(n)] for u in range(n)]
    for u, v, weight in edges:
        distance[u][v] = weight
        distance[v][u] = weight
    for middle in range(n):
        for source in range(n):
            if distance[source][middle] == INF:
                continue
            for target in range(n):
                candidate = distance[source][middle] + distance[middle][target]
                if candidate < distance[source][target]:
                    distance[source][target] = candidate
    return distance


def _prepare(n, masks, distance):
    nearest = [[0] * n for _ in range(K)]
    for vertex in range(n):
        nearest[0][vertex] = vertex
    for level in range(1, K):
        candidates = [vertex for vertex in range(n)
                      if masks[level - 1] >> vertex & 1]
        for vertex in range(n):
            nearest[level][vertex] = min(
                candidates, key=lambda candidate: (distance[vertex][candidate], candidate)
            )

    layers = ((1 << n) - 1, *masks, 0)
    bunch = [[False] * n for _ in range(n)]
    for center in range(n):
        for level in range(K):
            current, following = layers[level], layers[level + 1]
            boundary = min((distance[center][candidate] for candidate in range(n)
                            if following >> candidate & 1), default=INF)
            for vertex in range(n):
                if (current >> vertex & 1 and not (following >> vertex & 1)
                        and distance[center][vertex] < boundary):
                    bunch[center][vertex] = True
    return nearest, bunch


def _even_index(vertex, threshold, nearest, distance):
    result = 0
    for level in (2, 0):
        if distance[vertex][nearest[level][vertex]] <= threshold:
            result = level
            break
    return result


def _best_gap(vertex, upper_even, nearest, distance):
    # At k=4 the only nonempty candidate range is {0} when upper_even is 2.
    best_j = -1
    best_gap = -1
    for j in range(0, upper_even - 1, 2):
        gap = (distance[vertex][nearest[j + 2][vertex]]
               - distance[vertex][nearest[j][vertex]])
        if gap > best_gap:
            best_gap = gap
            best_j = j
    return best_j


def _refine_further(source, target, even_source, nearest, bunch, distance):
    if even_source < 2:
        return False
    j = _best_gap(source, even_source, nearest, distance)
    if bunch[target][nearest[j][source]] or bunch[source][nearest[j + 1][target]]:
        return True
    return (bunch[target][nearest[even_source][source]]
            or bunch[source][nearest[even_source + 1][target]])


def _refined_value(source, target, initial, nearest, bunch, distance):
    value = initial
    even_source = _even_index(source, value, nearest, distance)
    if not _refine_further(source, target, even_source, nearest, bunch, distance):
        return value

    iteration = 0
    while (_refine_further(source, target, even_source, nearest, bunch, distance)
           and iteration <= 15):
        value = (2 * value) // 3
        even_source = _even_index(source, value, nearest, distance)
        iteration += 1

    upper_even = _even_index(source, (3 * value) // 2, nearest, distance)
    if upper_even < 2:
        return INVALID_RESULT  # Unreachable under Figure 4's input promise.
    j = _best_gap(source, upper_even, nearest, distance)
    pivot = nearest[j][source]
    if bunch[target][pivot]:
        return distance[source][pivot] + distance[target][pivot]
    pivot = nearest[j + 1][target]
    if bunch[source][pivot]:
        return distance[source][pivot] + distance[target][pivot]
    pivot = nearest[upper_even][source]
    if bunch[target][pivot]:
        return distance[source][pivot] + distance[target][pivot]
    pivot = nearest[upper_even + 1][target]
    return distance[source][pivot] + distance[target][pivot]


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, masks, edges, _graph, source, target, estimate = parsed
    distance = _all_pairs(n, edges)
    if any(distance[u][v] == INF for u in range(n) for v in range(n)):
        return INVALID_RESULT
    true_distance = distance[source][target]
    if not true_distance <= estimate <= ALPHA * K * true_distance:
        return INVALID_RESULT
    nearest, bunch = _prepare(n, masks, distance)
    return _refined_value(source, target, estimate, nearest, bunch, distance)

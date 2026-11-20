"""Independent path-enumeration reference for Wulff--Nilsen Figure 4."""

from __future__ import annotations

from wulff_nilsen_distance_refinement_oracle import (
    ALPHA, K, MAX_M, MAX_N, MAX_PARSEABLE_INPUT_LENGTH, MAX_BASE_WEIGHT,
    SCALE, INVALID_RESULT, INF, MAX_RESULT_BOUND,
)


def _decode(values, input_is_null, input_length):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (tuple, list)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if len(values) < 8 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
           for value in values):
        return None
    n, m = values[0], values[1]
    if not 2 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 8 + 3 * m:
        return None
    masks = [values[2], values[3], values[4]]
    full = (1 << n) - 1
    if any(mask <= 0 or mask & ~full for mask in masks):
        return None
    if masks[1] & ~masks[0] or masks[2] & ~masks[1]:
        return None
    adjacency = [[] for _ in range(n)]
    last_u, last_v = -1, -1
    for i in range(m):
        u, v, weight = values[5 + 3 * i:8 + 3 * i]
        if (not 0 <= u < v < n or weight < SCALE or weight > MAX_BASE_WEIGHT * SCALE
                or weight % SCALE != 0 or (u, v) <= (last_u, last_v)):
            return None
        last_u, last_v = u, v
        adjacency[u].append((v, weight))
        adjacency[v].append((u, weight))
    at = 5 + 3 * m
    source, target, estimate = values[at:at + 3]
    if (not 0 <= source < n or not 0 <= target < n or source == target
            or estimate <= 0 or estimate % SCALE):
        return None
    return n, masks, adjacency, source, target, estimate


def _enumerate_path_distances(adjacency):
    """Enumerate every simple path from each origin, independently of Floyd."""
    n = len(adjacency)
    result = [[INF] * n for _ in range(n)]
    for origin in range(n):
        result[origin][origin] = 0

        def extend(vertex, visited, length):
            for neighbor, weight in adjacency[vertex]:
                bit = 1 << neighbor
                if visited & bit:
                    continue
                candidate = length + weight
                if candidate < result[origin][neighbor]:
                    result[origin][neighbor] = candidate
                extend(neighbor, visited | bit, candidate)

        extend(origin, 1 << origin, 0)
    return result


def _sample(vertex, level, masks, distance):
    if level == 0:
        return vertex
    candidates = (x for x in range(len(distance)) if masks[level - 1] >> x & 1)
    return min(candidates, key=lambda x: (distance[vertex][x], x))


def _is_in_bunch(center, candidate, masks, distance):
    layers = ((1 << len(distance)) - 1, *masks, 0)
    for level in range(K):
        if layers[level] >> candidate & 1 and not (layers[level + 1] >> candidate & 1):
            boundary = min((distance[center][x] for x in range(len(distance))
                            if layers[level + 1] >> x & 1), default=INF)
            if distance[center][candidate] < boundary:
                return True
    return False


def _even_level(vertex, threshold, masks, distance):
    # Search the even levels in descending order rather than using the primary's table.
    for level in (2, 0):
        if distance[vertex][_sample(vertex, level, masks, distance)] <= threshold:
            return level
    return 0


def _gap_index(source, upper, masks, distance):
    ranked = []
    for level in range(0, upper - 1, 2):
        gap = (distance[source][_sample(source, level + 2, masks, distance)]
               - distance[source][_sample(source, level, masks, distance)])
        ranked.append((gap, -level, level))
    return max(ranked)[2]


def _needs_more(source, target, upper, masks, distance):
    if upper < 2:
        return False
    split = _gap_index(source, upper, masks, distance)
    probes = (
        (target, _sample(source, split, masks, distance)),
        (source, _sample(target, split + 1, masks, distance)),
        (target, _sample(source, upper, masks, distance)),
        (source, _sample(target, upper + 1, masks, distance)),
    )
    return any(_is_in_bunch(center, point, masks, distance) for center, point in probes)


def _solve_query(source, target, initial, masks, distance):
    current = initial
    upper = _even_level(source, current, masks, distance)
    if not _needs_more(source, target, upper, masks, distance):
        return current
    step = 0
    while _needs_more(source, target, upper, masks, distance) and step <= 15:
        current = (2 * current) // 3
        upper = _even_level(source, current, masks, distance)
        step += 1
    upper = _even_level(source, (3 * current) // 2, masks, distance)
    if upper < 2:
        return INVALID_RESULT
    split = _gap_index(source, upper, masks, distance)
    candidates = (
        _sample(source, split, masks, distance),
        _sample(target, split + 1, masks, distance),
        _sample(source, upper, masks, distance),
        _sample(target, upper + 1, masks, distance),
    )
    centers = (target, source, target, source)
    for point, center in zip(candidates, centers):
        if _is_in_bunch(center, point, masks, distance):
            return distance[source][point] + distance[target][point]
    return INVALID_RESULT


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, masks, adjacency, source, target, estimate = parsed
    distance = _enumerate_path_distances(adjacency)
    if any(distance[u][v] == INF for u in range(n) for v in range(n)):
        return INVALID_RESULT
    exact = distance[source][target]
    if not exact <= estimate <= ALPHA * K * exact:
        return INVALID_RESULT
    return _solve_query(source, target, estimate, masks, distance)

"""Unexecuted reference models for exact-length weighted walks."""

NO_EDGE = 1000000
UNREACHABLE = -100000001
INVALID = -100000002
INF = 10**15


def parse(values):
    if not isinstance(values, (tuple, list)) or len(values) < 4 or len(values) > 261:
        return None
    if any(type(x) is not int for x in values):
        return None
    n, k, source, target = values[:4]
    if not (1 <= n <= 16 and 0 <= k <= 1000000
            and 0 <= source < n and 0 <= target < n and len(values) == 4+n*n):
        return None
    if any(x != NO_EDGE and not -100 <= x <= 100 for x in values[4:]):
        return None
    return n, k, source, target, values[4:]


def expected(values):
    data = parse(values)
    if data is None:
        return INVALID
    n, k, source, target, weights = data
    matrix = [[INF if weights[i*n+j] == NO_EDGE else weights[i*n+j]
               for j in range(n)] for i in range(n)]
    distance = [INF] * n
    distance[source] = 0
    while k:
        if k & 1:
            distance = [min((distance[i] + matrix[i][j]
                             for i in range(n) if distance[i] != INF and matrix[i][j] != INF),
                            default=INF) for j in range(n)]
        k >>= 1
        if k:
            matrix = [[min((matrix[i][p] + matrix[p][j] for p in range(n)
                            if matrix[i][p] != INF and matrix[p][j] != INF), default=INF)
                       for j in range(n)] for i in range(n)]
    return UNREACHABLE if distance[target] == INF else distance[target]


def expected_short(values):
    data = parse(values)
    if data is None:
        return INVALID
    n, k, source, target, weights = data
    if k > 64:
        raise ValueError("linear reference is restricted to short walks")
    distance = [None] * n
    distance[source] = 0
    for _ in range(k):
        following = [None] * n
        for i in range(n):
            if distance[i] is None:
                continue
            for j in range(n):
                weight = weights[i*n+j]
                if weight != NO_EDGE:
                    candidate = distance[i] + weight
                    if following[j] is None or candidate < following[j]:
                        following[j] = candidate
        distance = following
    return UNREACHABLE if distance[target] is None else distance[target]

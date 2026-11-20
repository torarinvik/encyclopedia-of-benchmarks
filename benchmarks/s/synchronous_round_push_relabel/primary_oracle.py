"""Deterministic bounded simulation of synchronous-round push-relabel."""

INVALID_RESULT = -1
MAX_VERTICES = 8
MAX_ARCS = 24
MAX_CAPACITY = 15
MAX_VALID_INPUT_LENGTH = 76
MAX_PARSEABLE_INPUT_LENGTH = 77
MAX_RESULT = 360


def _parse(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, source, sink = values[:4]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= m <= MAX_ARCS
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 4 + 3 * m):
        return None
    arcs = []
    for index in range(m):
        u, v, capacity = values[4 + 3 * index:7 + 3 * index]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= capacity <= MAX_CAPACITY):
            return None
        arcs.append((u, v, capacity))
    return n, source, sink, arcs


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, source, sink, arcs = parsed
    residual = [[0] * n for _ in range(n)]
    for u, v, capacity in arcs:
        residual[u][v] += capacity

    height = [0] * n
    height[source] = n
    excess = [0] * n
    for vertex in range(n):
        if vertex == source:
            continue
        amount = residual[source][vertex]
        if amount:
            residual[source][vertex] = 0
            residual[vertex][source] += amount
            excess[source] -= amount
            excess[vertex] += amount

    while True:
        active = [v for v in range(n)
                  if v != source and v != sink and excess[v] > 0 and height[v] < n]
        if not active:
            return excess[sink]

        change = [0] * n
        for u in active:
            remaining = excess[u]
            for v in range(n):
                if (remaining > 0 and residual[u][v] > 0
                        and height[u] == height[v] + 1):
                    amount = min(remaining, residual[u][v])
                    residual[u][v] -= amount
                    residual[v][u] += amount
                    change[u] -= amount
                    change[v] += amount
                    remaining -= amount

        new_excess = [excess[v] + change[v] for v in range(n)]
        new_height = height.copy()
        for u in active:
            if new_excess[u] <= 0:
                continue
            minimum = min((height[v] for v in range(n) if residual[u][v] > 0),
                          default=n)
            new_height[u] = minimum + 1

        excess = new_excess
        height = new_height


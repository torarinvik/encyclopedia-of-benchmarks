"""Unexecuted models of optimal chordal graph coloring."""


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 18
            or any(type(value) is not int for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= 16 or len(values) != n+1:
        return None
    rows = values[1:]
    if any(row < 0 or row >= 1 << n or row & (1 << v) for v, row in enumerate(rows)):
        return None
    if any(bool(rows[a] & (1 << b)) != bool(rows[b] & (1 << a))
           for a in range(n) for b in range(a)):
        return None
    return n, rows


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, rows = parsed
    selected, order, weights = 0, [], [0]*n
    for _ in range(n):
        v = max((v for v in range(n) if not selected & (1 << v)),
                key=lambda v: (weights[v], -v))
        earlier = rows[v] & selected
        for u in order:
            if earlier & (1 << u) and earlier & ~(rows[u] | (1 << u)):
                return -2
        order.append(v)
        selected |= 1 << v
        for u in range(n):
            if not selected & (1 << u) and rows[v] & (1 << u):
                weights[u] += 1
    colors = [-1]*n
    for v in order:
        used = {colors[u] for u in range(n) if rows[v] & (1 << u) and colors[u] >= 0}
        color = 0
        while color in used:
            color += 1
        colors[v] = color
    return max(colors) + 1


def independent(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, rows = parsed
    remaining = (1 << n) - 1
    while remaining:
        simplicial = None
        for v in range(n):
            if not remaining & (1 << v):
                continue
            neighbors = rows[v] & remaining
            if all(not (neighbors & (1 << u)) or not (neighbors & ~(rows[u] | (1 << u)))
                   for u in range(n)):
                simplicial = v
                break
        if simplicial is None:
            return -2
        remaining &= ~(1 << simplicial)
    best = 0
    for mask in range(1, 1 << n):
        if all(not (mask & (1 << v)) or not (mask & ~(rows[v] | (1 << v)))
               for v in range(n)):
            best = max(best, mask.bit_count())
    return best

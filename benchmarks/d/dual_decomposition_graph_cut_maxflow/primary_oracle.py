"""Finite exact fixed-point profile of two-way graph-cut dual decomposition."""

from math import gcd

INVALID_RESULT = -1
MIN_VERTICES = 3
MAX_VERTICES = 6
MAX_ARCS = 10
MAX_OVERLAP = 3
MAX_ITERATIONS = 8
MAX_VALID_INPUT_LENGTH = 62
MAX_PARSEABLE_INPUT_LENGTH = 63
DUAL_OFFSET = 7000
MAX_PACKED_RESULT = 74481


def _parse(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m, overlap, rounds = values[:4]
    if (not MIN_VERTICES <= n <= MAX_VERTICES or not 0 <= m <= MAX_ARCS
            or not 1 <= overlap <= MAX_OVERLAP or not 1 <= rounds <= MAX_ITERATIONS
            or len(values) != 4 + 3 * n + 4 * m):
        return None
    owner = list(values[4:4 + n])
    if (any(value not in (0, 1, 2) for value in owner)
            or any(owner.count(category) == 0 for category in (0, 1))
            or owner.count(2) != overlap):
        return None
    at = 4 + n
    source_caps = list(values[at:at + n])
    sink_caps = list(values[at + n:at + 2 * n])
    if any(cap < 0 or cap > 6 or cap % 2 for cap in source_caps + sink_caps):
        return None
    at += 2 * n
    edges = []
    for _ in range(m):
        u, v, uv, vu = values[at:at + 4]
        at += 4
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or (owner[u] == 0 and owner[v] == 1)
                or (owner[u] == 1 and owner[v] == 0)
                or any(cap < 0 or cap > 6 or cap % 2 for cap in (uv, vu))):
            return None
        edges.append((u, v, uv, vu))
    return n, m, overlap, rounds, owner, source_caps, sink_caps, edges


def _scale_for(rounds):
    # Include 2 so every shared even capacity can be halved exactly even at T=1.
    result = 2
    for divisor in range(1, rounds + 1):
        result = result * divisor // gcd(result, divisor)
    return result


def _solve_subproblem(parsed, side, lambda_scaled, scale):
    n, _, overlap, _, owner, source_caps, sink_caps, edges = parsed
    source, sink, size = n, n + 1, n + 2
    residual = [[0] * size for _ in range(size)]
    constant = 0
    for u in range(n):
        if owner[u] not in (side, 2):
            continue
        factor = scale // 2 if owner[u] == 2 else scale
        residual[source][u] += source_caps[u] * factor
        residual[u][sink] += sink_caps[u] * factor
    for u, v, uv, vu in edges:
        if owner[u] not in (side, 2) or owner[v] not in (side, 2):
            continue
        factor = scale // 2 if owner[u] == 2 and owner[v] == 2 else scale
        residual[u][v] += uv * factor
        residual[v][u] += vu * factor
    for u in range(n):
        if owner[u] != 2:
            continue
        lam = lambda_scaled[u]
        q = lam if side == 0 else -lam
        if q >= 0:
            residual[source][u] += q
        else:
            residual[u][sink] += -q
            constant += q

    flow = 0
    while True:
        parent = [-1] * size
        parent[source] = source
        queue = [source]
        head = 0
        while head < len(queue) and parent[sink] < 0:
            u = queue[head]
            head += 1
            for v in range(size):
                if parent[v] < 0 and residual[u][v] > 0:
                    parent[v] = u
                    queue.append(v)
                    if v == sink:
                        break
        if parent[sink] < 0:
            labels = [0 if parent[u] >= 0 else 1 for u in range(n)]
            return flow + constant, labels
        amount = sum(source_caps) * scale + sum(abs(value) for value in lambda_scaled) + 1
        v = sink
        while v != source:
            u = parent[v]
            amount = min(amount, residual[u][v])
            v = u
        v = sink
        while v != source:
            u = parent[v]
            residual[u][v] -= amount
            residual[v][u] += amount
            v = u
        flow += amount


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, _, overlap, rounds, owner, _, _, _ = parsed
    scale = _scale_for(rounds)
    lambda_scaled = [0] * n
    dual_scaled = 0
    agreement = False
    for iteration in range(1, rounds + 1):
        energy_m, labels_m = _solve_subproblem(parsed, 0, lambda_scaled, scale)
        energy_n, labels_n = _solve_subproblem(parsed, 1, lambda_scaled, scale)
        dual_scaled = energy_m + energy_n
        agreement = all(labels_m[u] == labels_n[u] for u in range(n) if owner[u] == 2)
        if agreement or iteration == rounds:
            break
        step = scale // iteration
        for u in range(n):
            if owner[u] == 2:
                lambda_scaled[u] += step * (labels_m[u] - labels_n[u])
    return 2 * (dual_scaled + DUAL_OFFSET) + int(agreement)

"""Small-domain subset reference plus direct checks for sparse large fixtures."""

MAX_N = 64
MAX_WEIGHT = 1_000_000


def _parse(values):
    if len(values) < 2 or len(values) > 6051:
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or m < 0 or m > n * (n - 1) // 2:
        return None
    if len(values) != 2 + 3 * m:
        return None
    edges = []
    used = set()
    for at in range(2, len(values), 3):
        u, v, weight = values[at:at + 3]
        if not (0 <= u < n and 0 <= v < n and u != v and 1 <= weight <= MAX_WEIGHT):
            return None
        key = (min(u, v), max(u, v))
        if key in used:
            return None
        used.add(key)
        edges.append((key[0], key[1], weight))
    return n, edges


def _component_answer(vertices, edges):
    index = {vertex: bit for bit, vertex in enumerate(vertices)}
    size = len(vertices)
    best_partner = [[] for _ in range(size)]
    for u, v, weight in edges:
        a, b = index[u], index[v]
        best_partner[a].append((b, weight))
        best_partner[b].append((a, weight))
    full = (1 << size) - 1
    dp = [0] * (1 << size)
    for mask in range(1, full + 1):
        bit = mask & -mask
        u = bit.bit_length() - 1
        rest = mask ^ bit
        value = dp[rest]
        for v, weight in best_partner[u]:
            other = 1 << v
            if rest & other:
                value = max(value, weight + dp[rest ^ other])
        dp[mask] = value
    return dp[full]


def _large_sparse_answer(n, edges):
    # The only large workload is a union of isolated edges. Handle the general
    # disjoint-edge case directly; other large fixtures are intentionally absent.
    used = set()
    for u, v, _ in edges:
        if u in used or v in used:
            return None
        used.add(u)
        used.add(v)
    return sum(weight for _, _, weight in edges)


def solve(values):
    parsed = _parse(values)
    if parsed is None:
        return -2
    n, edges = parsed
    if n <= 18:
        neighbors = [[] for _ in range(n)]
        for u, v, _ in edges:
            neighbors[u].append(v)
            neighbors[v].append(u)
        seen = set()
        total = 0
        for root in range(n):
            if root in seen:
                continue
            stack, component = [root], []
            seen.add(root)
            while stack:
                u = stack.pop()
                component.append(u)
                for v in neighbors[u]:
                    if v not in seen:
                        seen.add(v)
                        stack.append(v)
            component_set = set(component)
            local_edges = [e for e in edges if e[0] in component_set and e[1] in component_set]
            if len(component) > 1:
                total += _component_answer(component, local_edges)
        return total
    answer = _large_sparse_answer(n, edges)
    if answer is None:
        raise ValueError("primary oracle only defines the documented large sparse fixtures")
    return answer


expected_result = solve

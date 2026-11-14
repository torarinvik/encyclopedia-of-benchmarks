"""Unexecuted modular exact-walk counting reference drafts."""
MOD = 1_000_000_007


def parse(values):
    if (not isinstance(values, (tuple, list)) or not 4 <= len(values) <= 261
            or any(type(value) is not int for value in values)):
        return None
    n, k, source, target = values[:4]
    if (not 1 <= n <= 16 or not 0 <= k <= 1_000_000_000
            or not 0 <= source < n or not 0 <= target < n
            or len(values) != 4 + n*n or any(not 0 <= value <= 100 for value in values[4:])):
        return None
    return n, k, source, target, values[4:]


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, k, source, target, entries = parsed
    power = [list(entries[i*n:(i+1)*n]) for i in range(n)]
    vector = [0] * n
    vector[source] = 1
    while k:
        if k & 1:
            vector = [sum(vector[i] * power[i][j] for i in range(n)) % MOD for j in range(n)]
        k >>= 1
        if k:
            power = [[sum(power[i][p] * power[p][j] for p in range(n)) % MOD
                      for j in range(n)] for i in range(n)]
    return vector[target]


def expected_short(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, k, source, target, entries = parsed
    if k > 64:
        raise ValueError("linear reference is restricted to short walks")
    counts = [0] * n
    counts[source] = 1
    for _ in range(k):
        following = [0] * n
        for i in range(n):
            for j in range(n):
                following[j] = (following[j] + counts[i] * entries[i*n+j]) % MOD
        counts = following
    return counts[target]

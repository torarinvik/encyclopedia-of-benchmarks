"""Independent set-based verifier for the two-level insertion profile."""

MAX_INPUT_LENGTH = 55
MAX_OUTPUT_BYTES = 152


def verify(values, capacity=None, output_is_null=False):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if any(not isinstance(x, int) for x in values):
        return -1, b""
    n, q = values[0], values[1]
    if n not in (4, 9) or q < 0 or q > 24 or len(values) < 3+2*q:
        return -1, b""
    p = 2
    edges = set()
    updates = []
    for _ in range(q):
        u, v = values[p:p+2]
        p += 2
        if not 0 <= u < v < n or (u, v) in edges:
            return -1, b""
        edges.add((u, v))
        updates.append((u, v))
    if p >= len(values): return -1, b""
    count = values[p]
    p += 1
    if count < 0 or len(values) != p+count: return -1, b""
    tape = values[p:]
    if any(t < 0 or t >= n for t in tape): return -1, b""
    levels = [0]*n
    mates = [-1]*n
    tape_i = 0
    threshold = int(n**0.5)

    def neighbors(u):
        return sorted(v if a == u else a for a, v in edges if a == u or v == u)

    def owned(u):
        own = []
        for v in neighbors(u):
            if levels[u] == levels[v] == 0 or levels[u] > levels[v] or (levels[u] == levels[v] == 1 and u < v):
                own.append(v)
        return own

    def repair(z):
        if z < 0 or levels[z] != 0 or mates[z] != -1: return
        for v in neighbors(z):
            if levels[v] == 0 and mates[v] == -1:
                mates[z], mates[v] = v, z
                return

    def promotion(u):
        nonlocal tape_i
        available = owned(u)
        if not available or tape_i == len(tape) or tape[tape_i] >= len(available):
            return False
        v = available[tape[tape_i]]
        tape_i += 1
        old_u, old_v = mates[u], mates[v]
        for x in (u, old_u, v, old_v):
            if x >= 0: mates[x] = -1
        mates[u], mates[v] = v, u
        levels[u] = levels[v] = 1
        for x in sorted({old_u, old_v}): repair(x)
        return True

    edges.clear()
    for u, v in updates:
        edges.add((u, v))
        if levels[u] == levels[v] == 0:
            if mates[u] == -1 and mates[v] == -1:
                mates[u], mates[v] = v, u
            counts = (len(owned(u)), len(owned(v)))
            who = u if counts[0] > counts[1] or (counts[0] == counts[1] and u < v) else v
            if len(owned(who)) >= threshold and not promotion(who):
                return -1, b""
    if tape_i != len(tape): return -1, b""
    out = b"".join(int(x).to_bytes(8, "little", signed=True) for x in (n, *levels, *mates))
    if output_is_null or (capacity is not None and capacity < len(out)):
        return -2, b""
    return len(out), out

"""Primary independent-set inclusion-exclusion oracle for chromatic number."""

MAX_VERTICES = 7
MAX_EDGES = 21
MAX_INPUT_LENGTH = 44
MAX_OUTPUT_BYTES = 8


def evaluate(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 0 <= m <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + 2 * m:
        return -1, b""
    adjacency = [0] * n
    seen = set()
    for i in range(2, len(values), 2):
        a, b = values[i:i + 2]
        if not (0 <= a < n and 0 <= b < n) or a == b:
            return -1, b""
        edge = (min(a, b), max(a, b))
        if edge in seen:
            return -1, b""
        seen.add(edge)
        adjacency[a] |= 1 << b
        adjacency[b] |= 1 << a
    count = [0] * (1 << n)
    count[0] = 1
    for mask in range(1, 1 << n):
        bit = mask & -mask
        v = bit.bit_length() - 1
        rest = mask ^ bit
        count[mask] = count[rest] + count[rest & ~adjacency[v]]
    chi = n
    for k in range(1, n + 1):
        total = 0
        for mask, independent_count in enumerate(count):
            term = (independent_count - 1) ** k
            total += term if (n - mask.bit_count()) % 2 == 0 else -term
        if total > 0:
            chi = k
            break
    return 8, int(chi).to_bytes(8, "little", signed=True)

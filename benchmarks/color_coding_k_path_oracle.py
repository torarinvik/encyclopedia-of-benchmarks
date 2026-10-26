"""Primary subset/endpoint DP oracle for colorful k-path existence."""

MAX_N = 12
MAX_EDGES = 66
MAX_K = 6
MAX_INPUT_LENGTH = 147
MAX_OUTPUT_BYTES = 8


def evaluate(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m, k = values[:3]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_EDGES or not 1 <= k <= min(MAX_K, n):
        return -1, b""
    edge_start = 3 + n
    if len(values) != edge_start + 2 * m:
        return -1, b""
    colors = values[3:edge_start]
    if any(color < 0 or color >= k for color in colors):
        return -1, b""
    adjacency = [0] * n
    seen = set()
    for pos in range(edge_start, len(values), 2):
        a, b = values[pos:pos+2]
        if not (0 <= a < n and 0 <= b < n) or a == b or (min(a,b),max(a,b)) in seen:
            return -1, b""
        seen.add((min(a,b),max(a,b)))
        adjacency[a] |= 1 << b
        adjacency[b] |= 1 << a
    states = [[False] * n for _ in range(1 << k)]
    for v in range(n):
        states[1 << colors[v]][v] = True
    answer = False
    full_size = (1 << k) - 1
    for mask in range(1 << k):
        for v in range(n):
            if not states[mask][v]:
                continue
            if mask == full_size:
                answer = True
                break
            neighbors = adjacency[v]
            while neighbors:
                bit = neighbors & -neighbors
                u = bit.bit_length() - 1
                neighbors ^= bit
                color_bit = 1 << colors[u]
                if mask & color_bit == 0:
                    states[mask | color_bit][u] = True
        if answer:
            break
    raw = int(answer).to_bytes(8, "little", signed=True)
    return 8, raw

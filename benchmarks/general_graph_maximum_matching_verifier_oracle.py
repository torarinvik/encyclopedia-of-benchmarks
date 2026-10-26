"""Independent subset-DP verifier for general-graph matching cardinality."""
from functools import lru_cache

MAX_INPUT_LENGTH = 134
MAX_OUTPUT_BYTES = 8


def verify(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m = values[:2]
    if any(not isinstance(x, int) for x in (n, m)) or not 2 <= n <= 12 or not 0 <= m <= n*(n-1)//2 or len(values) != 2+2*m:
        return -1, b""
    neighbors = [0]*n
    seen = set()
    for e in range(m):
        u, v = values[2+2*e:4+2*e]
        if not isinstance(u,int) or not isinstance(v,int) or not 0 <= u < v < n or (u,v) in seen:
            return -1,b""
        seen.add((u,v));neighbors[u] |= 1<<v;neighbors[v] |= 1<<u

    @lru_cache(None)
    def optimum(mask):
        if mask == 0: return 0
        bit = mask & -mask
        u = bit.bit_length()-1
        rest = mask ^ bit
        best = optimum(rest)
        candidates = neighbors[u] & rest
        while candidates:
            vbit = candidates & -candidates
            candidates ^= vbit
            best = max(best, 1 + optimum(rest ^ vbit))
        return best

    value = optimum((1<<n)-1)
    return 8, value.to_bytes(8,"little",signed=True)

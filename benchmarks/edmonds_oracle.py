"""Exhaustive independent oracle for bounded minimum arborescence."""
from itertools import product
MAX_VERTICES = 5
MAX_EDGES = 12
MAX_WEIGHT = 100
MAX_INPUT_LENGTH = 3 + 3 * MAX_EDGES

def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int for x in values)):
        return -1
    n, root, m = values[:3]
    if not 1 <= n <= MAX_VERTICES or not 0 <= root < n or not 0 <= m <= MAX_EDGES or len(values) != 3 + 3*m:
        return -1
    incoming = [[] for _ in range(n)]
    for i in range(m):
        u,v,w=values[3+3*i:6+3*i]
        if not (0 <= u < n and 0 <= v < n and 0 <= w <= MAX_WEIGHT): return -1
        if u != v and v != root: incoming[v].append((u,w))
    if n == 1: return 0
    if any(not incoming[v] for v in range(n) if v != root): return -1
    choices=[incoming[v] for v in range(n) if v != root]
    best=None
    for selected in product(*choices):
        parents={v:u for v,(u,w) in zip((v for v in range(n) if v != root),selected)}
        valid=True
        for start in parents:
            seen=set(); cur=start
            while cur != root:
                if cur in seen or cur not in parents:
                    valid=False; break
                seen.add(cur); cur=parents[cur]
            if not valid: break
        if valid:
            cost=sum(w for u,w in selected)
            if best is None or cost<best: best=cost
    return -1 if best is None else best

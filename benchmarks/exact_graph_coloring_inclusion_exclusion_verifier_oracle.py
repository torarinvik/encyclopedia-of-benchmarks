"""Independent brute-force coloring verifier using restricted-growth labels."""


def verify(values):
    if values is None or len(values) < 2 or len(values) > 44:
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= 7 or not 0 <= m <= 21 or len(values) != 2 + 2*m:
        return -1, b""
    edges = []
    seen = set()
    for i in range(2, len(values), 2):
        a, b = values[i:i+2]
        if a < 0 or b < 0 or a >= n or b >= n or a == b:
            return -1, b""
        edge = (min(a,b), max(a,b))
        if edge in seen:
            return -1, b""
        seen.add(edge)
        edges.append(edge)
    adjacent = [[False]*n for _ in range(n)]
    for a,b in edges:
        adjacent[a][b]=adjacent[b][a]=True
    colors=[0]*n
    answer=n
    for limit in range(1,n+1):
        def assign(v, used):
            if v==n:
                return True
            for c in range(min(used+1,limit)):
                if any(adjacent[v][u] and colors[u]==c for u in range(v)):
                    continue
                colors[v]=c
                if assign(v+1,max(used,c+1)):
                    return True
            return False
        if assign(0,0):
            answer=limit
            break
    return 8, answer.to_bytes(8,"little",signed=True)

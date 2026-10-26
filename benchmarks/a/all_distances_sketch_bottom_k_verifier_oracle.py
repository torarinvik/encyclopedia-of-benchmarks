"""Independent rank-prefix verifier for bottom-k ADS output."""

MAX_INPUT_LENGTH = 104
MAX_OUTPUT_BYTES = 168


def verify(values):
    if values is None or len(values) < 6 or len(values) > 104:
        return -1, b""
    n, m, k, root = values[0:4]
    if any(not isinstance(z, int) for z in (n, m, k, root)) or not (2 <= n <= 10 and 0 <= m <= n*(n-1) and 1 <= k <= n and 0 <= root < n):
        return -1, b""
    if len(values) != 4+n+2*m:
        return -1, b""
    order = values[4:4+n]
    if any(not isinstance(z, int) for z in order) or set(order) != set(range(n)):
        return -1, b""
    graph = [[False]*n for _ in range(n)]
    for e in range(m):
        a, b = values[4+n+2*e:6+n+2*e]
        if not isinstance(a,int) or not isinstance(b,int) or a<0 or b<0 or a>=n or b>=n or a==b or graph[a][b]:
            return -1,b""
        graph[a][b]=True
    # Floyd-style reachability layers, independent of the primary BFS queue.
    distance = [[-1]*n for _ in range(n)]
    for i in range(n): distance[i][i]=0
    for i in range(n):
        for j in range(n):
            if graph[i][j]: distance[i][j]=1
    for mid in range(n):
        for i in range(n):
            for j in range(n):
                if distance[i][mid]>=0 and distance[mid][j]>=0:
                    candidate=distance[i][mid]+distance[mid][j]
                    if distance[i][j]<0 or candidate<distance[i][j]: distance[i][j]=candidate
    reachable = [(distance[root][v],v) for v in range(n) if distance[root][v]>=0]
    reachable.sort()
    selected=[]
    for idx,(d,v) in enumerate(reachable):
        prefix=[order[w] for _,w in reachable[:idx+1]]
        if order[v] in sorted(prefix)[:k]: selected.append((v,d))
    out=[len(selected)]
    for v,d in selected: out.extend((v,d))
    raw=b"".join(int(x).to_bytes(8,"little",signed=True) for x in out)
    return len(raw),raw

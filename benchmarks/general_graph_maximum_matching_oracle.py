"""Primary deterministic Edmonds blossom oracle for general graphs."""

MAX_INPUT_LENGTH = 134
MAX_OUTPUT_BYTES = 8


def _parse(a):
    if a is None or len(a) < 2 or len(a) > MAX_INPUT_LENGTH:
        return None
    n, m = a[:2]
    if any(not isinstance(x, int) for x in (n, m)) or not 2 <= n <= 12 or not 0 <= m <= n*(n-1)//2:
        return None
    if len(a) != 2 + 2*m:
        return None
    adj = [[False]*n for _ in range(n)]
    for e in range(m):
        u, v = a[2+2*e:4+2*e]
        if not isinstance(u, int) or not isinstance(v, int) or not 0 <= u < v < n or adj[u][v]:
            return None
        adj[u][v] = adj[v][u] = True
    return n, adj


def _edmonds(adj):
    n = len(adj)
    match = [-1]*n
    parent = [-1]*n
    base = list(range(n))
    used = [False]*n
    blossom = [False]*n

    def lca(a, b):
        seen = [False]*n
        while True:
            a = base[a]
            seen[a] = True
            if match[a] == -1:
                break
            a = parent[match[a]]
        while True:
            b = base[b]
            if seen[b]:
                return b
            b = parent[match[b]]

    def mark_path(v, b, child):
        while base[v] != b:
            blossom[base[v]] = True
            blossom[base[match[v]]] = True
            parent[v] = child
            child = match[v]
            v = parent[match[v]]

    def find_path(root):
        nonlocal parent, base, used, blossom
        used = [False]*n
        parent = [-1]*n
        base = list(range(n))
        queue = [root]
        used[root] = True
        head = 0
        while head < len(queue):
            v = queue[head]
            head += 1
            for u in range(n):
                if not adj[v][u] or base[v] == base[u] or match[v] == u:
                    continue
                if u == root or (match[u] != -1 and parent[match[u]] != -1):
                    cur = lca(v, u)
                    blossom = [False]*n
                    mark_path(v, cur, u)
                    mark_path(u, cur, v)
                    for i in range(n):
                        if blossom[base[i]]:
                            base[i] = cur
                            if not used[i]:
                                used[i] = True
                                queue.append(i)
                elif parent[u] == -1:
                    parent[u] = v
                    if match[u] == -1:
                        x = u
                        while x != -1:
                            pv = parent[x]
                            nxt = match[pv] if pv != -1 else -1
                            if pv != -1:
                                match[x] = pv
                                match[pv] = x
                            x = nxt
                        return True
                    mate = match[u]
                    used[mate] = True
                    queue.append(mate)
        return False

    for v in range(n):
        if match[v] == -1:
            find_path(v)
    return sum(m >= 0 for m in match)//2


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, adj = parsed
    size = _edmonds(adj)
    return 8, int(size).to_bytes(8, "little", signed=True)

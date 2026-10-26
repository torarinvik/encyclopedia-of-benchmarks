"""Independent bounded DFS verifier for colorful k-path existence."""


def verify(values):
    if values is None or len(values) < 3:
        return -1, b""
    n, m, k = values[:3]
    if n < 1 or n > 12 or m < 0 or m > 66 or k < 1 or k > 6 or k > n:
        return -1, b""
    split = 3 + n
    if len(values) != split + 2*m:
        return -1, b""
    color = values[3:split]
    if any(c < 0 or c >= k for c in color):
        return -1, b""
    graph = [[] for _ in range(n)]
    edges = set()
    for i in range(split, len(values), 2):
        a, b = values[i:i+2]
        edge = (a,b) if a < b else (b,a)
        if a < 0 or b < 0 or a >= n or b >= n or a == b or edge in edges:
            return -1, b""
        edges.add(edge)
        graph[a].append(b)
        graph[b].append(a)
    def walk(vertex, used_vertices, used_colors, depth):
        if depth == k:
            return True
        for neighbor in graph[vertex]:
            bit = 1 << neighbor
            color_bit = 1 << color[neighbor]
            if not (used_vertices & bit) and not (used_colors & color_bit):
                if walk(neighbor, used_vertices | bit, used_colors | color_bit, depth+1):
                    return True
        return False
    found = False
    for start in range(n):
        if walk(start, 1 << start, 1 << color[start], 1):
            found = True
            break
    result = int(found).to_bytes(8, "little", signed=True)
    return 8, result

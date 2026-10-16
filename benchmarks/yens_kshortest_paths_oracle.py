"""Small deterministic oracle for Yen's loopless k-shortest paths."""

from __future__ import annotations
import heapq

MAX_VERTICES = 8
MAX_K = 8
MAX_INPUT_LENGTH = 4 + MAX_VERTICES * MAX_VERTICES
MAX_OUTPUT_BYTES = 8 * (1 + MAX_K * (2 + MAX_VERTICES))


def expected(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    n, k, src, dst = values[:4]
    if (any(type(x) is not int for x in (n,k,src,dst)) or not 1 <= n <= MAX_VERTICES or
            not 1 <= k <= MAX_K or not 0 <= src < n or not 0 <= dst < n or len(values) != 4+n*n):
        return -1, b""
    matrix = [values[4+i*n:4+(i+1)*n] for i in range(n)]
    if any(type(w) is not int or w < -1 or w > 1000 for row in matrix for w in row):
        return -1, b""

    def shortest(start: int, banned_nodes: set[int], banned_edges: set[tuple[int, int]]) -> tuple[int, ...] | None:
        # Keep complete paths in the queue to make equal-cost ties lexicographic.
        q: list[tuple[int, tuple[int, ...]]] = [(0, (start,))]
        while q:
            cost, path = heapq.heappop(q)
            u = path[-1]
            if u == dst:
                return path
            for v, weight in enumerate(matrix[u]):
                if weight >= 0 and v not in banned_nodes and (u, v) not in banned_edges and v not in path:
                    heapq.heappush(q, (cost + weight, path + (v,)))
        return None

    first = shortest(src, set(), set())
    if first is None:
        paths: list[tuple[int, ...]] = []
    else:
        paths = [first]
    pool: dict[tuple[int, ...], int] = {}
    while len(paths) < k and paths:
        prev = paths[-1]
        for i in range(len(prev)-1):
            root = prev[:i+1]
            excluded = {(p[i], p[i+1]) for p in paths if len(p) > i+1 and p[:i+1] == root}
            spur = shortest(root[-1], set(root[:-1]), excluded)
            if spur is not None:
                full = root[:-1] + spur
                cost = sum(matrix[a][b] for a, b in zip(full, full[1:]))
                pool[full] = cost
        if not pool:
            break
        selected = min(pool, key=lambda p: (pool[p], p))
        del pool[selected]
        paths.append(selected)
    out = bytearray()
    def put(x: int) -> None: out.extend(int(x).to_bytes(8, "little", signed=True))
    put(len(paths))
    for path in paths:
        put(len(path))
        for node in path: put(node)
        put(sum(matrix[a][b] for a, b in zip(path, path[1:])))
    return len(out), bytes(out)

expected_output = expected

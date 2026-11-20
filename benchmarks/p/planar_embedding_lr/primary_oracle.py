"""Clean-room left-right planarity embedding reference for the bounded profile."""

from __future__ import annotations


class _Interval:
    __slots__ = ("low", "high")

    def __init__(self, low: int = -1, high: int = -1) -> None:
        self.low = low
        self.high = high

    def empty(self) -> bool:
        return self.low < 0


class _Conflict:
    __slots__ = ("left", "right")

    def __init__(self, left: _Interval | None = None, right: _Interval | None = None) -> None:
        self.left = left or _Interval()
        self.right = right or _Interval()

    def swap(self) -> None:
        self.left, self.right = self.right, self.left


def _read(values: list[int]) -> tuple[int, list[tuple[int, int]]] | None:
    if len(values) < 2:
        return None
    n, m = values[:2]
    if not (1 <= n <= 32 and 0 <= m <= 96) or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for i in range(m):
        u, v = values[2 + 2 * i : 4 + 2 * i]
        if not (0 <= u < v < n) or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def planar_embedding_lr(values: list[int]) -> bytes | None:
    """Return status plus one byte per rotation neighbor, or None for invalid input.

    The primary reference uses a DFS orientation and left/right conflict pairs.
    Its embedding phase orders the outgoing DFS arcs and inserts return edges
    around their resolved left/right references.
    """
    parsed = _read(values)
    if parsed is None:
        return None
    n, edges = parsed
    m = len(edges)
    adj: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    edge_of: dict[tuple[int, int], int] = {}
    for eid, (u, v) in enumerate(edges):
        adj[u].append((v, eid))
        adj[v].append((u, eid))
        edge_of[(u, v)] = eid
    for row in adj:
        row.sort()

    tail = [-1] * m
    head = [-1] * m
    height = [-1] * n
    parent = [-1] * n
    low = [0] * m
    low2 = [0] * m
    nest = [0] * m
    roots: list[int] = []

    def orient(v: int) -> None:
        pe = parent[v]
        for w, eid in adj[v]:
            if tail[eid] >= 0:
                continue
            tail[eid], head[eid] = v, w
            low[eid] = low2[eid] = height[v]
            if height[w] < 0:
                parent[w] = eid
                height[w] = height[v] + 1
                orient(w)
                nest[eid] = 2 * low[eid] + (1 if low2[eid] < height[v] else 0)
            else:
                low[eid] = height[w]
                low2[eid] = height[v]
                nest[eid] = 2 * low[eid] + (1 if low2[eid] < height[v] else 0)
            if pe >= 0:
                if low[eid] < low[pe]:
                    low2[pe] = min(low[pe], low2[eid])
                    low[pe] = low[eid]
                elif low[eid] > low[pe]:
                    low2[pe] = min(low2[pe], low[eid])
                else:
                    low2[pe] = min(low2[pe], low2[eid])

    for root in range(n):
        if height[root] < 0:
            height[root] = 0
            roots.append(root)
            orient(root)

    outgoing: list[list[int]] = [[] for _ in range(n)]
    for eid in range(m):
        outgoing[tail[eid]].append(eid)
    for row in outgoing:
        row.sort(key=lambda e: (nest[e], head[e]))

    # Intervals contain return edges, represented by their lowest and highest
    # lowpoint edge. A reference chain aligns intervals that cannot be merged.
    ref = [-1] * m
    side = [1] * m
    low_edge = [-1] * m
    bottom = [-1] * m
    stack: list[_Conflict] = []
    planar = True

    def interval_conflicts(interval: _Interval, e: int) -> bool:
        return interval.high >= 0 and low[interval.high] > low[e]

    def interval_min(pair: _Conflict) -> int:
        x = low[pair.left.low] if pair.left.low >= 0 else n + 1
        y = low[pair.right.low] if pair.right.low >= 0 else n + 1
        return min(x, y)

    def add_constraints(ei: int, parent_edge: int) -> bool:
        pair = _Conflict()
        while True:
            if not stack:
                return False
            q = stack.pop()
            if not q.left.empty():
                q.swap()
            if not q.left.empty():
                return False
            if low[q.right.low] > low[parent_edge]:
                if pair.right.empty():
                    pair.right = _Interval(q.right.low, q.right.high)
                else:
                    ref[pair.right.low] = q.right.high
                    pair.right.low = q.right.low
            else:
                ref[q.right.low] = low_edge[parent_edge]
            if len(stack) - 1 == bottom[ei]:
                break
        while stack and (interval_conflicts(stack[-1].left, ei) or interval_conflicts(stack[-1].right, ei)):
            q = stack.pop()
            if interval_conflicts(q.right, ei):
                q.swap()
            if interval_conflicts(q.right, ei):
                return False
            if pair.right.low >= 0:
                ref[pair.right.low] = q.right.high
            if q.right.low >= 0:
                pair.right.low = q.right.low
            if pair.left.empty():
                pair.left = _Interval(q.left.low, q.left.high)
            elif pair.left.low >= 0:
                ref[pair.left.low] = q.left.high
                pair.left.low = q.left.low
        if not pair.left.empty() or not pair.right.empty():
            stack.append(pair)
        return True

    def remove_parent_returns(e: int) -> None:
        u = tail[e]
        while stack and interval_min(stack[-1]) == height[u]:
            q = stack.pop()
            if q.left.low >= 0:
                side[q.left.low] = -1
        if stack:
            q = stack.pop()
            while q.left.high >= 0 and head[q.left.high] == u:
                q.left.high = ref[q.left.high]
            if q.left.high < 0 and q.left.low >= 0:
                ref[q.left.low] = q.right.low
                side[q.left.low] = -1
                q.left.low = -1
            while q.right.high >= 0 and head[q.right.high] == u:
                q.right.high = ref[q.right.high]
            if q.right.high < 0 and q.right.low >= 0:
                ref[q.right.low] = q.left.low
                side[q.right.low] = -1
                q.right.low = -1
            stack.append(q)
        if low[e] < height[u] and stack:
            q = stack[-1]
            lh, rh = q.left.high, q.right.high
            if lh >= 0 and (rh < 0 or low[lh] > low[rh]):
                ref[e] = lh
            else:
                ref[e] = rh

    def test(v: int) -> bool:
        pe = parent[v]
        for index, eid in enumerate(outgoing[v]):
            bottom[eid] = len(stack) - 1
            w = head[eid]
            if parent[w] == eid:
                if not test(w):
                    return False
            else:
                low_edge[eid] = eid
                stack.append(_Conflict(right=_Interval(eid, eid)))
                if low[eid] < height[v]:
                    if index == 0:
                        if pe >= 0:
                            low_edge[pe] = low_edge[eid]
                    elif pe < 0 or not add_constraints(eid, pe):
                        return False
        if pe >= 0:
            remove_parent_returns(pe)
        return True

    for root in roots:
        if not test(root):
            planar = False
            break
    if not planar:
        return bytes((0,))

    def resolve(eid: int) -> int:
        target = ref[eid]
        if target >= 0:
            side[eid] *= resolve(target)
            ref[eid] = -1
        return side[eid]

    signed_nest = [nest[e] * resolve(e) for e in range(m)]
    for row in outgoing:
        row.sort(key=lambda e: (signed_nest[e], head[e]))
    rotation: list[list[int]] = [[head[e] for e in row] for row in outgoing]
    left_ref = [-1] * n
    right_ref = [-1] * n

    def insert_before(v: int, w: int, reference: int) -> None:
        row = rotation[v]
        if not row:
            row.append(w)
            return
        row.insert(row.index(reference), w)

    def insert_after(v: int, w: int, reference: int) -> None:
        row = rotation[v]
        if not row:
            row.append(w)
            return
        row.insert((row.index(reference) + 1) % len(row), w)

    def embed(v: int) -> None:
        for eid in outgoing[v]:
            w = head[eid]
            if parent[w] == eid:
                rotation[w].insert(0, v)
                left_ref[v] = right_ref[v] = w
                embed(w)
            elif side[eid] == 1:
                insert_after(w, v, right_ref[w])
            else:
                insert_before(w, v, left_ref[w])
                left_ref[w] = v

    for root in roots:
        embed(root)
    out = bytearray((1,))
    for row in rotation:
        out.extend(row)
    return bytes(out)


if __name__ == "__main__":  # pragma: no cover - import-only reference file
    raise SystemExit("This module is a reference implementation; it is not a program.")

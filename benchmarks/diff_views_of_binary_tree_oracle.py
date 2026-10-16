"""Oracle for four binary-tree views (right, left, top, bottom)."""
from __future__ import annotations

MAX_NODES = 1023
I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1
VIEWS = {"right": 0, "left": 1, "top": 2, "bottom": 3}

def view(nodes: list[list[int]], root: int, kind: str) -> list[int] | None:
    if kind not in VIEWS or not isinstance(nodes, list) or len(nodes) > MAX_NODES:
        return None
    n = len(nodes)
    if n == 0:
        return [] if root == -1 else None
    if type(root) is not int or not 0 <= root < n:
        return None
    parents = [0] * n
    for row in nodes:
        if not isinstance(row, list) or len(row) != 3 or any(type(x) is not int for x in row):
            return None
        value, left, right = row
        if not I32_MIN <= value <= I32_MAX or left < -1 or right < -1 or left >= n or right >= n:
            return None
        for child in (left, right):
            if child >= 0:
                parents[child] += 1
                if parents[child] > 1:
                    return None
    if parents[root] or any(parents[i] != 1 for i in range(n) if i != root):
        return None
    queue = [(root, 0, 0)]
    head = 0
    seen = set()
    by_depth: dict[int, list[int]] = {}
    by_column: dict[int, list[int]] = {}
    while head < len(queue):
        node, depth, column = queue[head]
        head += 1
        if node in seen:
            return None
        seen.add(node)
        value, left, right = nodes[node]
        by_depth.setdefault(depth, []).append(value)
        by_column.setdefault(column, []).append(value)
        if left >= 0:
            queue.append((left, depth + 1, column - 1))
        if right >= 0:
            queue.append((right, depth + 1, column + 1))
    if len(seen) != n:
        return None
    if kind == "right":
        return [by_depth[d][-1] for d in sorted(by_depth)]
    if kind == "left":
        return [by_depth[d][0] for d in sorted(by_depth)]
    if kind == "top":
        return [by_column[c][0] for c in sorted(by_column)]
    return [by_column[c][-1] for c in sorted(by_column)]

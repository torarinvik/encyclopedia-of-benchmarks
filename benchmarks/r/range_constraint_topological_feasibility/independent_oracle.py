"""Expanded-range reference for bounded precedence feasibility."""
from itertools import permutations

def expected(values):
    if values is None or len(values) < 2:
        return -1
    n, m = values[:2]
    if not 1 <= n <= 4096 or not 0 <= m <= 8192 or len(values) != 2 + 4*m:
        return -1
    constraints = []
    for offset in range(2, len(values), 4):
        kind, left, right, target = values[offset:offset+4]
        if (kind not in (1, 2, 3) or not 0 <= left < right <= n
                or not 0 <= target < n or left <= target < right):
            return -1
        constraints.append((kind, left, right, target))
    emitted = [False] * n
    for _ in range(n):
        for candidate in range(n):
            if emitted[candidate]:
                continue
            eligible = True
            for kind, left, right, target in constraints:
                if kind == 1 and left <= candidate < right and not emitted[target]:
                    eligible = False
                elif candidate == target and kind == 2 and not all(emitted[left:right]):
                    eligible = False
                elif candidate == target and kind == 3 and not any(emitted[left:right]):
                    eligible = False
                if not eligible:
                    break
            if eligible:
                emitted[candidate] = True
                break
        else:
            return 0
    return 1


def exhaustive_small(values):
    """Enumerate orders independently of the greedy reference (n <= 8)."""
    n, m = values[:2]
    if not 1 <= n <= 8 or len(values) != 2 + 4 * m:
        raise ValueError("exhaustive reference requires a valid small frame")
    constraints = [values[2 + 4*i:6 + 4*i] for i in range(m)]
    for order in permutations(range(n)):
        rank = [0] * n
        for index, vertex in enumerate(order):
            rank[vertex] = index
        feasible = True
        for kind, left, right, target in constraints:
            if kind == 1:
                feasible = all(rank[target] < rank[v] for v in range(left, right))
            elif kind == 2:
                feasible = all(rank[v] < rank[target] for v in range(left, right))
            else:
                feasible = any(rank[v] < rank[target] for v in range(left, right))
            if not feasible:
                break
        if feasible:
            return 1
    return 0

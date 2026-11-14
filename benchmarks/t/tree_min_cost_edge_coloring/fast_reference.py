"""Unexecuted matching-sensitivity construction for tree edge coloring.

The subset and exhaustive models in reference.py are independent small-case
oracles. This module drafts the scalable algorithm, not a verified result.
"""
from .reference import parse

INF = 10**15


def matching_and_deletions(cost):
    """Return optimum row assignment and all single-column deletion costs.

    `cost` has d rows and either d or d+1 columns. For the latter, all d+1
    deletion values are found from one rectangular assignment and shortest
    alternating exchanges. Equal-cost ties are allowed.
    """
    d = len(cost)
    width = len(cost[0]) if d else 1
    if d == 0:
        return 0, [0]
    if width not in (d, d+1) or any(len(row) != width for row in cost):
        raise ValueError("invalid assignment dimensions")
    # Incrementally augment a rectangular minimum-cost row matching using
    # row/column duals. Column zero is a temporary unmatched sentinel.
    row_dual = [0] * (d+1)
    col_dual = [0] * (width+1)
    owner = [0] * (width+1)
    for row in range(1, d+1):
        owner[0] = row
        previous = [0] * (width+1)
        slack = [INF] * (width+1)
        used = [False] * (width+1)
        col = 0
        while True:
            used[col] = True
            current_row = owner[col]
            step, next_col = INF, 0
            for candidate in range(1, width+1):
                if used[candidate]:
                    continue
                reduced = cost[current_row-1][candidate-1] - row_dual[current_row] - col_dual[candidate]
                if reduced < slack[candidate]:
                    slack[candidate] = reduced
                    previous[candidate] = col
                if slack[candidate] < step:
                    step, next_col = slack[candidate], candidate
            if next_col == 0:
                raise ValueError("assignment has no augmenting column")
            for candidate in range(width+1):
                if used[candidate]:
                    row_dual[owner[candidate]] += step
                    col_dual[candidate] -= step
                elif candidate:
                    slack[candidate] -= step
            col = next_col
            if owner[col] == 0:
                break
        while col:
            parent = previous[col]
            owner[col] = owner[parent]
            col = parent
    base = sum(cost[owner[col]-1][col-1] for col in range(1, width+1) if owner[col])
    if width == d:
        return base, []
    free = next(col-1 for col in range(1, width+1) if owner[col] == 0)
    # Removing a matched column frees its row. An exchange moves that row to
    # another column; following these exchanges ends at the free column.
    # Optimality of the original matching excludes negative exchange cycles.
    distance = [INF] * width
    distance[free] = 0
    for _ in range(d):
        updated = distance[:]
        for col in range(width):
            row = owner[col+1] - 1
            if row < 0:
                continue
            for dest in range(width):
                if distance[dest] != INF:
                    updated[col] = min(updated[col], cost[row][dest] - cost[row][col] + distance[dest])
        distance = updated
    return base, [base + delta for delta in distance]


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    n, k, parents, costs = parsed
    children = [[] for _ in range(n)]
    degree = [0] * n
    for child, parent in enumerate(parents, 1):
        children[parent].append(child)
        degree[parent] += 1
        degree[child] += 1
    if max(degree) > k:
        return -2
    prices = sorted(costs)
    tables = [None] * n
    for vertex in range(n-1, -1, -1):
        d = len(children[vertex])
        if not d:
            tables[vertex] = [0]
            continue
        # At a saturated root there is no parent edge to forbid, and all k
        # colors are used. Other vertices use d+1 candidate colors.
        saturated_root = vertex == 0 and d == k
        width = d if saturated_root else d+1
        rows = [[prices[color] + tables[child][min(color, len(tables[child])-1)]
                 for color in range(width)] for child in children[vertex]]
        base, deletions = matching_and_deletions(rows)
        tables[vertex] = [base] if saturated_root else deletions
    return tables[0][0] if len(children[0]) == k else tables[0][-1]

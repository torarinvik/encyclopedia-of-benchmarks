"""Independent rectangular-assignment reference; not executed."""


def expected(values):
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= 354
            or any(type(value) is not int for value in values)):
        return -1
    n, k = values[:2]
    if not 1 <= n <= 32 or not 1 <= k <= 10 or len(values) != n + 1 + n*k:
        return -1
    parents = values[2:n+1]
    costs = values[n+1:]
    if (any(not 0 <= parent < vertex for vertex, parent in enumerate(parents, 1))
            or any(not 0 <= value <= 1_000_000 for value in costs)):
        return -1
    children = [[] for _ in range(n)]
    for vertex, parent in enumerate(parents, 1):
        children[parent].append(vertex)
    if any(len(group) >= k for group in children):
        return -2

    # Rectangular minimum assignment, using potentials and augmenting paths.
    def assignment(matrix):
        rows = len(matrix)
        if rows == 0:
            return 0
        columns = len(matrix[0])
        u = [0] * (rows + 1)
        v = [0] * (columns + 1)
        owner = [0] * (columns + 1)
        previous = [0] * (columns + 1)
        for row in range(1, rows + 1):
            owner[0] = row
            minimum = [10**15] * (columns + 1)
            used = [False] * (columns + 1)
            column = 0
            while True:
                used[column] = True
                active_row = owner[column]
                delta, next_column = 10**15, 0
                for j in range(1, columns + 1):
                    if used[j]:
                        continue
                    reduced = matrix[active_row-1][j-1] - u[active_row] - v[j]
                    if reduced < minimum[j]:
                        minimum[j], previous[j] = reduced, column
                    if minimum[j] < delta:
                        delta, next_column = minimum[j], j
                for j in range(columns + 1):
                    if used[j]:
                        u[owner[j]] += delta
                        v[j] -= delta
                    else:
                        minimum[j] -= delta
                column = next_column
                if owner[column] == 0:
                    break
            while column:
                parent_column = previous[column]
                owner[column] = owner[parent_column]
                column = parent_column
        return -v[0]

    dp = [[0] * k for _ in range(n)]
    for vertex in range(n-1, -1, -1):
        for color in range(k):
            allowed = [other for other in range(k) if other != color]
            matrix = [[dp[child][other] for other in allowed]
                      for child in children[vertex]]
            dp[vertex][color] = costs[vertex*k+color] + assignment(matrix)
    return min(dp[0])


def brute_small(values):
    """Enumerate complete colorings on small inputs, independently of assignment DP."""
    from itertools import product

    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= 354
            or any(type(value) is not int for value in values)):
        return -1
    n, k = values[:2]
    if not 1 <= n <= 32 or not 1 <= k <= 10 or len(values) != n + 1 + n*k:
        return -1
    parents, costs = values[2:n+1], values[n+1:]
    if (any(not 0 <= parent < vertex for vertex, parent in enumerate(parents, 1))
            or any(not 0 <= value <= 1_000_000 for value in costs)):
        return -1
    if k**n > 100_000:
        raise ValueError("exhaustive reference bound exceeded")
    best = None
    for colors in product(range(k), repeat=n):
        used = [set() for _ in range(n)]
        valid = True
        for vertex, parent in enumerate(parents, 1):
            color = colors[vertex]
            if color == colors[parent] or color in used[parent]:
                valid = False
                break
            used[parent].add(color)
        if valid:
            total = sum(costs[vertex*k+color] for vertex, color in enumerate(colors))
            if best is None or total < best:
                best = total
    return -2 if best is None else best

"""Label-based recursive contraction model; unexecuted draft."""


def expected_result(values):
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= 132
            or any(type(value) is not int for value in values)):
        return -1
    n, m, q = values[:3]
    if not (2 <= n <= 12 and 1 <= m <= 32 and 0 <= q <= 64
            and len(values) == 3 + 2*m + q):
        return -1
    edges = list(zip(values[3:3+2*m:2], values[4:3+2*m:2]))
    if any(u < 0 or u >= n or v < 0 or v >= n or u == v for u, v in edges):
        return -1
    reached = {0}
    while True:
        expanded = reached | {v for u, v in edges if u in reached} | {u for u, v in edges if v in reached}
        if expanded == reached:
            break
        reached = expanded
    if len(reached) != n:
        return -1
    tape = values[3+2*m:]
    position = 0
    targets = {7: 6, 8: 7, 9: 8, 10: 9, 11: 9, 12: 10}

    def solve(labels):
        nonlocal position
        components = sorted(set(labels))
        if len(components) <= 6:
            first = components[0]
            remaining = components[1:]
            best = m + 1
            for mask in range((1 << len(remaining)) - 1):
                side = {first} | {c for i, c in enumerate(remaining) if mask & (1 << i)}
                best = min(best, sum((labels[u] in side) != (labels[v] in side) for u, v in edges))
            return best
        results = []
        for _ in range(2):
            branch = labels[:]
            count = len(components)
            while count > targets[len(components)]:
                candidates = [(u, v) for u, v in edges if branch[u] != branch[v]]
                if position >= len(tape) or not 0 <= tape[position] < len(candidates):
                    raise ValueError("invalid rank tape")
                u, v = candidates[tape[position]]
                position += 1
                old, new = branch[v], branch[u]
                branch = [new if label == old else label for label in branch]
                count -= 1
            results.append(solve(branch))
        return min(results)

    try:
        result = solve(list(range(n)))
    except ValueError:
        return -1
    return result if position == len(tape) else -1

"""Primary oracle for the bounded, fixed-sample FRT tree-metric profile."""

MAX_INPUT_LENGTH = 74
MAX_OUTPUT_BYTES = 512


def _within(distance, beta_q, level):
    if level >= 0:
        return distance * 1024 <= beta_q * (1 << level)
    return distance * 1024 * (1 << -level) <= beta_q


def _valid(values):
    if values is None or len(values) < 8 or len(values) > MAX_INPUT_LENGTH:
        return False
    n, beta_q = values[0], values[1]
    if not isinstance(n, int) or not 2 <= n <= 8:
        return False
    if not isinstance(beta_q, int) or not 1024 <= beta_q <= 2047:
        return False
    if len(values) != 2 + n + n*n:
        return False
    permutation = values[2:2+n]
    if sorted(permutation) != list(range(n)):
        return False
    matrix = [values[2+n+i*n:2+n+(i+1)*n] for i in range(n)]
    for i in range(n):
        for j in range(n):
            d = matrix[i][j]
            if not isinstance(d, int) or d < 0 or d > 255:
                return False
            if (d != 0) != (i != j) or d != matrix[j][i]:
                return False
    return all(matrix[i][j] <= matrix[i][k] + matrix[k][j]
               for i in range(n) for j in range(n) for k in range(n))


def evaluate(values):
    if not _valid(values):
        return -1, b""
    n, beta_q = values[:2]
    order = values[2:2+n]
    matrix = [values[2+n+i*n:2+n+(i+1)*n] for i in range(n)]
    maximum = max(max(row) for row in matrix)
    high = (maximum - 1).bit_length()
    clusters = [list(range(n))]
    result = [[0] * n for _ in range(n)]
    for level in range(high, -11, -1):
        refined = []
        tree_distance = 1 << (level + 13)
        for cluster in clusters:
            left = set(cluster)
            children = []
            for center in order:
                if center not in left:
                    continue
                child = [v for v in order if v in left and
                         _within(matrix[center][v], beta_q, level)]
                if not child:
                    child = [center]
                children.append(child)
                left.difference_update(child)
            for a in range(len(children)):
                for b in range(a):
                    for u in children[a]:
                        for v in children[b]:
                            result[u][v] = result[v][u] = tree_distance
            refined.extend(children)
        clusters = refined
    if any(result[i][j] == 0 for i in range(n) for j in range(n) if i != j):
        return -1, b""
    raw = b"".join(x.to_bytes(8, "little", signed=True)
                   for row in result for x in row)
    return len(raw), raw

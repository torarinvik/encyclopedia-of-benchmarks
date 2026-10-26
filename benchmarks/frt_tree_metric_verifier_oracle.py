"""Independent level-label verifier for the bounded FRT sample profile."""

MAX_INPUT_LENGTH = 74
MAX_OUTPUT_BYTES = 512


def _valid(a):
    if a is None or not 8 <= len(a) <= 74:
        return False
    n, q = a[0], a[1]
    if not isinstance(n, int) or n < 2 or n > 8 or not isinstance(q, int) or q < 1024 or q > 2047:
        return False
    if len(a) != 2 + n + n*n:
        return False
    p = a[2:2+n]
    if set(p) != set(range(n)):
        return False
    d = a[2+n:]
    for i in range(n):
        for j in range(n):
            x = d[i*n+j]
            if not isinstance(x, int) or x < 0 or x > 255:
                return False
            if (i == j and x != 0) or (i != j and x == 0):
                return False
            if x != d[j*n+i]:
                return False
    return all(d[i*n+j] <= d[i*n+k] + d[k*n+j]
               for i in range(n) for j in range(n) for k in range(n))


def verify(a):
    if not _valid(a):
        return -1, b""
    n, q = a[0], a[1]
    permutation = a[2:2+n]
    d = a[2+n:]
    high = (max(d) - 1).bit_length()
    labels = [0] * n
    answer = [[0] * n for _ in range(n)]
    for level in range(high, -11, -1):
        # Give each current block a label, then refine that block by ordered
        # radius neighborhoods. Labels are local to this level only.
        old_blocks = {}
        for vertex, label in enumerate(labels):
            old_blocks.setdefault(label, []).append(vertex)
        new_labels = [-1] * n
        next_label = 0
        radius_scale = 1 << level if level >= 0 else None
        for members in old_blocks.values():
            unassigned = set(members)
            children = []
            for center in permutation:
                if center not in unassigned:
                    continue
                child = []
                for vertex in permutation:
                    if vertex not in unassigned:
                        continue
                    inside = (d[center*n+vertex] * 1024 <= q * radius_scale
                              if level >= 0 else
                              d[center*n+vertex] * 1024 * (1 << -level) <= q)
                    if inside:
                        child.append(vertex)
                if not child:
                    child = [center]
                for vertex in child:
                    new_labels[vertex] = next_label
                next_label += 1
                children.append(child)
                unassigned.difference_update(child)
            tree_distance = 1 << (level + 13)
            for i in range(n):
                for j in range(i):
                    # A pair receives the value at its first level of separation.
                    if labels[i] == labels[j] and new_labels[i] != new_labels[j] and answer[i][j] == 0:
                        answer[i][j] = answer[j][i] = tree_distance
        labels = new_labels
    raw = b"".join(value.to_bytes(8, "little", signed=True)
                   for row in answer for value in row)
    return len(raw), raw

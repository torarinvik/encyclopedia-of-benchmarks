"""Independent bitset verifier for the Chapter 99 neighborhood reduction."""

MAX_INPUT_LENGTH = 135
MAX_OUTPUT_BYTES = 200


def verify(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m, center = values[0], values[1], values[2]
    if n < 1 or n > 12 or m < 0 or m > 66 or center < 0 or center >= n or len(values) != 3 + 2*m:
        return -1, b""
    masks = [0] * n
    seen = set()
    for pos in range(3, len(values), 2):
        a, b = values[pos], values[pos + 1]
        if a < 0 or b <= a or b >= n or (a, b) in seen:
            return -1, b""
        seen.add((a, b))
        masks[a] |= 1 << b
        masks[b] |= 1 << a

    neighborhood = masks[center]
    closed = neighborhood | (1 << center)
    exits = 0
    for u in range(n):
        if neighborhood & (1 << u) and masks[u] & ~closed:
            exits |= 1 << u
    guards = 0
    for u in range(n):
        bit = 1 << u
        if neighborhood & bit and not exits & bit and masks[u] & exits:
            guards |= bit
    prisoners = neighborhood & ~(exits | guards)
    if prisoners == 0:
        return -1, b""

    survivors = [u for u in range(n) if not ((guards | prisoners) >> u & 1)]
    size = len(survivors) + 1
    mapping = [-1] * n
    for new, old in enumerate(survivors):
        mapping[old] = new
    table = [size, *survivors, -1]
    transformed = [0] * size
    for new_u, old_u in enumerate(survivors):
        old_mask = masks[old_u]
        for old_v in survivors:
            if old_mask & (1 << old_v):
                transformed[new_u] |= 1 << mapping[old_v]
    p = mapping[center]
    leaf = size - 1
    transformed[p] |= 1 << leaf
    transformed[leaf] = 1 << p
    table.extend(transformed)
    result = b"".join(x.to_bytes(8, "little", signed=True) for x in table)
    return len(result), result

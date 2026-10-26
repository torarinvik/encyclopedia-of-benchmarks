"""Bottom-up canonical zero-suppressed decision diagram for an explicit family."""
MAX_INPUT_LENGTH = 34
MAX_OUTPUT_BYTES = 1536
MAX_OUTPUT_ELEMENTS = 192


def evaluate(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, family_size = values[0], values[1]
    if not 1 <= n <= 6 or not 0 <= family_size <= 32 or len(values) != 2 + family_size:
        return -1, b""
    limit = 1 << n
    family = values[2:]
    if any(mask < 0 or mask >= limit for mask in family) or len(set(family)) != len(family):
        return -1, b""
    ids = [0] * limit
    for mask in family:
        ids[mask] = 1
    nodes = []
    for variable in range(n):
        current = []
        unique = {}
        for p in range(len(ids) // 2):
            low, high = ids[2 * p], ids[2 * p + 1]
            if high == 0:
                current.append(low)
                continue
            key = (variable, low, high)
            if key not in unique:
                unique[key] = 2 + len(nodes)
                nodes.append(key)
            current.append(unique[key])
        ids = current
    counts = [0, 1]
    for _var, low, high in nodes:
        counts.append(counts[low] + counts[high])
    root = ids[0]
    result = [root, len(nodes), counts[root]]
    for node in nodes:
        result.extend(node)
    raw = b"".join(int(x).to_bytes(8, "little", signed=True) for x in result)
    return len(raw), raw

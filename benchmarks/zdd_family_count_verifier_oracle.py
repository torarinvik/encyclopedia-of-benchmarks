"""Independent recursive family partitioner for canonical ZDD serialization."""
MAX_INPUT_LENGTH = 34
MAX_OUTPUT_BYTES = 1536
MAX_OUTPUT_ELEMENTS = 192


def verify(values):
    if values is None or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m = values[0], values[1]
    if n < 1 or n > 6 or m < 0 or m > 32 or len(values) != m + 2:
        return -1, b""
    domain = 1 << n
    masks = values[2:]
    if any(mask < 0 or mask >= domain for mask in masks) or len(set(masks)) != m:
        return -1, b""
    members = set(masks)
    level_nodes = [[] for _ in range(n)]
    seen = [set() for _ in range(n)]

    def partition(variable, prefix):
        if variable < 0:
            return 1 if prefix in members else 0
        low = partition(variable - 1, prefix)
        high = partition(variable - 1, prefix | (1 << variable))
        if high == 0:
            return low
        key = (variable, low, high)
        if key not in seen[variable]:
            seen[variable].add(key)
            level_nodes[variable].append(key)
        return key

    root_key = partition(n - 1, 0)
    ids = {0: 0, 1: 1}
    nodes = []
    counts = [0, 1]
    for variable in range(n):
        for key in level_nodes[variable]:
            _, low, high = key
            node = (variable, ids[low], ids[high])
            ids[key] = 2 + len(nodes)
            nodes.append(node)
            counts.append(counts[node[1]] + counts[node[2]])
    root = ids[root_key]
    flat = [root, len(nodes), counts[root]]
    for node in nodes:
        flat.extend(node)
    raw = b"".join(int(x).to_bytes(8, "little", signed=True) for x in flat)
    return len(raw), raw

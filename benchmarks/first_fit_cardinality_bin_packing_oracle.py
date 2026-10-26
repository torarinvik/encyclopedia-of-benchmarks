"""Bounded first-fit packing with both capacity and cardinality limits."""
MAX_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 264
MAX_OUTPUT_ELEMENTS = 33


def evaluate(values):
    if values is None or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, item_limit, capacity = values[:3]
    if not 1 <= n <= 32 or not 1 <= item_limit <= 32 or not 1 <= capacity <= 10000 or len(values) != n + 3:
        return -1, b""
    items = values[3:]
    if any(size <= 0 or size > capacity for size in items):
        return -1, b""
    loads, counts, assignment = [], [], []
    for size in items:
        chosen = None
        for b in range(len(loads)):
            if counts[b] < item_limit and loads[b] + size <= capacity:
                chosen = b
                break
        if chosen is None:
            chosen = len(loads)
            loads.append(0)
            counts.append(0)
        loads[chosen] += size
        counts[chosen] += 1
        assignment.append(chosen)
    result = [len(loads), *assignment]
    raw = b"".join(int(x).to_bytes(8, "little", signed=True) for x in result)
    return len(raw), raw

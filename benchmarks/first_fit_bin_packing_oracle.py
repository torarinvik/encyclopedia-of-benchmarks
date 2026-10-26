"""Primary reference implementation for bounded First Fit bin packing."""

MAX_ITEMS = 64
SCALE = 1_000_000
MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 520


def evaluate(values):
    if values is None or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    n = values[0]
    if not 0 <= n <= MAX_ITEMS or len(values) != n + 1:
        return -1, b""
    items = values[1:]
    if any(size < 1 or size > SCALE for size in items):
        return -1, b""
    loads = []
    assignment = []
    for size in items:
        for bin_id, load in enumerate(loads):
            if load + size <= SCALE:
                loads[bin_id] += size
                assignment.append(bin_id)
                break
        else:
            loads.append(size)
            assignment.append(len(loads) - 1)
    result = [len(loads), *assignment]
    raw = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    return len(raw), raw

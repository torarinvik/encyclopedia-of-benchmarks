"""Primary reference model for the bounded affine-hash Count-Min sketch."""

P = 2_147_483_647
MAX_DEPTH = 4
MAX_WIDTH = 8
MAX_OPERATIONS = 16
MAX_INPUT_LENGTH = 59
MAX_OUTPUT_BYTES = 128


def evaluate(values):
    if values is None or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    depth, width, operation_count = values[:3]
    if not (1 <= depth <= MAX_DEPTH and 1 <= width <= MAX_WIDTH and 0 <= operation_count <= MAX_OPERATIONS):
        return -1, b""
    if len(values) != 3 + 2 * depth + 3 * operation_count:
        return -1, b""
    params = [(values[3 + 2*j], values[4 + 2*j]) for j in range(depth)]
    if any(not (1 <= a < P and 0 <= b < P) for a, b in params):
        return -1, b""
    counters = [[0] * width for _ in range(depth)]
    results = []
    offset = 3 + 2 * depth
    for op in range(operation_count):
        kind, key, weight = values[offset + 3*op:offset + 3*op + 3]
        if not 0 <= key <= 1_000_000:
            return -1, b""
        slots = [((a * key + b) % P) % width for a, b in params]
        if kind == 0:
            if not 1 <= weight <= 1_000_000:
                return -1, b""
            for row, slot in enumerate(slots):
                counters[row][slot] += weight
        elif kind == 1:
            if weight != 0:
                return -1, b""
            results.append(min(counters[row][slot] for row, slot in enumerate(slots)))
        else:
            return -1, b""
    return len(results) * 8, b"".join(x.to_bytes(8, "little", signed=True) for x in results)

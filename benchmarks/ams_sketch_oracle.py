"""Primary reference model for bounded fast-AMS second-moment estimation."""

MAX_INPUT_LENGTH = 116


def evaluate(values):
    if values is None or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    depth, width, key_count, update_count = values[:4]
    if depth not in (1, 3, 5) or not 1 <= width <= 8 or not 1 <= key_count <= 8 or not 0 <= update_count <= 16:
        return -1, b""
    map_end = 4 + 2 * depth * key_count
    if len(values) != map_end + 2 * update_count:
        return -1, b""
    mappings = []
    for row in range(depth):
        entries = []
        for key in range(key_count):
            bucket, sign = values[4 + 2 * (row * key_count + key):6 + 2 * (row * key_count + key)]
            if bucket < 0 or bucket >= width or sign not in (-1, 1):
                return -1, b""
            entries.append((bucket, sign))
        mappings.append(entries)
    updates = []
    for pos in range(map_end, len(values), 2):
        key, weight = values[pos:pos+2]
        if key < 0 or key >= key_count or weight < -1000 or weight > 1000:
            return -1, b""
        updates.append((key, weight))
    table = [[0] * width for _ in range(depth)]
    for key, weight in updates:
        for row in range(depth):
            bucket, sign = mappings[row][key]
            table[row][bucket] += weight * sign
    estimates = sorted(sum(counter * counter for counter in row) for row in table)
    estimate = estimates[depth // 2]
    return 8, estimate.to_bytes(8, "little", signed=True)

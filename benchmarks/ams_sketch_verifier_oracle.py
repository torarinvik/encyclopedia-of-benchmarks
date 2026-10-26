"""Independent AMS verifier with mapping-keyed counter dictionaries."""


def verify(values):
    if values is None or len(values) < 4:
        return -1, b""
    depth, width, keys, updates = values[0:4]
    if depth not in (1, 3, 5) or width not in range(1, 9) or keys not in range(1, 9) or updates not in range(17):
        return -1, b""
    offset = 4 + 2 * depth * keys
    if len(values) != offset + 2 * updates:
        return -1, b""
    hash_table = {}
    cursor = 4
    for row in range(depth):
        for item in range(keys):
            bucket, sign = values[cursor], values[cursor + 1]
            cursor += 2
            if not 0 <= bucket < width or sign not in (-1, 1):
                return -1, b""
            hash_table[row, item] = bucket, sign
    counters = [dict() for _ in range(depth)]
    for cursor in range(offset, len(values), 2):
        item, amount = values[cursor], values[cursor + 1]
        if not 0 <= item < keys or not -1000 <= amount <= 1000:
            return -1, b""
        for row in range(depth):
            bucket, sign = hash_table[row, item]
            counters[row][bucket] = counters[row].get(bucket, 0) + amount * sign
    row_norms = sorted(sum(value * value for value in row.values()) for row in counters)
    answer = row_norms[len(row_norms) // 2]
    return 8, answer.to_bytes(8, "little", signed=True)

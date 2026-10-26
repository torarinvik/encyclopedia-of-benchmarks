"""Independent verifier model using row-major flat storage and a separate parser."""

PRIME = 2_147_483_647


def verify(values):
    if values is None or len(values) < 3:
        return -1, b""
    depth, width, count = values[0], values[1], values[2]
    if depth < 1 or depth > 4 or width < 1 or width > 8 or count < 0 or count > 16:
        return -1, b""
    params_end = 3 + 2 * depth
    if len(values) != params_end + 3 * count:
        return -1, b""
    hashes = []
    for r in range(depth):
        a, b = values[3 + 2*r:5 + 2*r]
        if a <= 0 or a >= PRIME or b < 0 or b >= PRIME:
            return -1, b""
        hashes.append((a, b))
    table = [0] * (depth * width)
    answers = bytearray()
    for pos in range(params_end, len(values), 3):
        kind, key, amount = values[pos:pos+3]
        if key < 0 or key > 1_000_000:
            return -1, b""
        indices = [r * width + ((a * key + b) % PRIME) % width for r, (a,b) in enumerate(hashes)]
        if kind == 0:
            if amount < 1 or amount > 1_000_000:
                return -1, b""
            for idx in indices:
                table[idx] += amount
        elif kind == 1:
            if amount != 0:
                return -1, b""
            estimate = table[indices[0]]
            for idx in indices[1:]:
                if table[idx] < estimate:
                    estimate = table[idx]
            answers.extend(estimate.to_bytes(8, "little", signed=True))
        else:
            return -1, b""
    return len(answers), bytes(answers)

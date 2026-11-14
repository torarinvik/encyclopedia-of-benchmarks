"""Degree-and-edge-XOR reference for deterministic XOR filter construction."""


def expected_output(values, input_is_null=False, input_length=None):
    if input_is_null or (input_length is not None and input_length != len(values)) or len(values) < 3:
        return -1
    n, slots, q = values[:3]
    if not (0 <= n <= 32 and 3 <= slots <= 96 and 0 <= q <= 32 and len(values) == 3 + 4*(n+q)):
        return -1
    records = [values[3+4*i:7+4*i] for i in range(n+q)]
    for a, b, c, fingerprint in records:
        if not (0 <= a < slots and 0 <= b < slots and 0 <= c < slots
                and a != b and a != c and b != c and 0 <= fingerprint <= 255):
            return -1
    degree, edge_xor = [0]*slots, [0]*slots
    for edge in range(n):
        for slot in records[edge][:3]:
            degree[slot] += 1
            edge_xor[slot] ^= edge
    queue = [slot for slot in range(slots) if degree[slot] == 1]
    stack = []
    head = 0
    while head < len(queue):
        slot = queue[head]
        head += 1
        if degree[slot] != 1:
            continue
        edge = edge_xor[slot]
        stack.append((slot, edge))
        for v in records[edge][:3]:
            degree[v] -= 1
            edge_xor[v] ^= edge
            if degree[v] == 1:
                queue.append(v)
    if len(stack) != n:
        return -2
    table = [0]*slots
    for slot, edge in reversed(stack):
        a, b, c, f = records[edge]
        table[slot] = f ^ table[a] ^ table[b] ^ table[c]
    result = 0
    for i, (a, b, c, f) in enumerate(records[n:]):
        if table[a] ^ table[b] ^ table[c] == f:
            result += i+1
    return result

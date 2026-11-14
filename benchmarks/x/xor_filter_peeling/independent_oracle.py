"""Adjacency-list model of deterministic three-way XOR-filter peeling."""

from collections import deque


def expected_output(values, input_is_null=False, input_length=None):
    if input_is_null or (input_length is not None and input_length != len(values)) or len(values) < 3:
        return -1
    n, slots, q = values[:3]
    if not (0 <= n <= 32 and 3 <= slots <= 96 and 0 <= q <= 32 and len(values) == 3 + 4*(n+q)):
        return -1
    records = [tuple(values[3+4*i:7+4*i]) for i in range(n+q)]
    if any(not (0 <= a < slots and 0 <= b < slots and 0 <= c < slots
                and len({a, b, c}) == 3 and 0 <= f <= 255)
           for a, b, c, f in records):
        return -1
    adjacency = [set() for _ in range(slots)]
    for edge, (a, b, c, _) in enumerate(records[:n]):
        for slot in (a, b, c):
            adjacency[slot].add(edge)
    queue = deque(slot for slot in range(slots) if len(adjacency[slot]) == 1)
    stack = []
    while queue:
        slot = queue.popleft()
        if len(adjacency[slot]) != 1:
            continue
        edge = next(iter(adjacency[slot]))
        stack.append((slot, edge))
        for v in records[edge][:3]:
            adjacency[v].remove(edge)
            if len(adjacency[v]) == 1:
                queue.append(v)
    if len(stack) != n:
        return -2
    table = [0] * slots
    for slot, edge in reversed(stack):
        a, b, c, f = records[edge]
        table[slot] = f ^ table[a] ^ table[b] ^ table[c]
    return sum(i+1 for i, (a, b, c, f) in enumerate(records[n:]) if table[a] ^ table[b] ^ table[c] == f)

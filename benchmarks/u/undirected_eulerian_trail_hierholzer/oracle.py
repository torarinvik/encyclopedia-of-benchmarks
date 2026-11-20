"""Reference for the bounded undirected edge-ID traversal contract."""

import struct

def solve(frame):
    if len(frame) < 2:
        return -1, []
    n, m = frame[:2]
    if not (1 <= n <= 16 and 0 <= m <= 32 and len(frame) == 2 + 2 * m):
        return -1, []
    adjacency = [[] for _ in range(n)]
    for edge in range(m):
        u, v = frame[2 + 2 * edge:4 + 2 * edge]
        if not (0 <= u < n and 0 <= v < n):
            return -1, []
        adjacency[u].append((edge, v))
        adjacency[v].append((edge, u))
    odds = [v for v in range(n) if len(adjacency[v]) % 2]
    if len(odds) not in (0, 2):
        return 0, []
    start = odds[0] if odds else next((v for v in range(n) if adjacency[v]), 0)
    positions = [0] * n
    used = [False] * m
    stack = [start]
    reverse = []
    while stack:
        v = stack[-1]
        while positions[v] < len(adjacency[v]) and used[adjacency[v][positions[v]][0]]:
            positions[v] += 1
        if positions[v] == len(adjacency[v]):
            reverse.append(stack.pop())
        else:
            edge, other = adjacency[v][positions[v]]
            positions[v] += 1
            used[edge] = True
            stack.append(other)
    if len(reverse) != m + 1:
        return 0, []
    return 8 * len(reverse), list(reversed(reverse))


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or values is None:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""
    status, path = solve(values)
    if status <= 0:
        return status, b""
    if output_is_null or (capacity is not None and capacity < status):
        return -2, b""
    return status, b"".join(struct.pack("<q", vertex) for vertex in path)

"""Recursive edge scan reference, independent of the stack implementation."""
import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or values is None or (input_length is not None and input_length != len(values)):
        return -1, b""
    if len(values) < 2 or any(type(x) is not int for x in values):
        return -1, b""
    n, m = values[:2]
    if not (1 <= n <= 16 and 0 <= m <= 32 and len(values) == 2 + 2*m):
        return -1, b""
    edges = [(values[2+2*i], values[3+2*i]) for i in range(m)]
    if any(u < 0 or v < 0 or u >= n or v >= n for u, v in edges):
        return -1, b""
    degrees = [0] * n
    for u, v in edges:
        degrees[u] += 1
        degrees[v] += 1
    odd = [v for v in range(n) if degrees[v] % 2]
    if len(odd) not in (0, 2):
        return 0, b""
    start = odd[0] if odd else next((v for v in range(n) if degrees[v]), 0)
    remaining = [True] * m
    result = []

    def visit(v):
        for i, (u, w) in enumerate(edges):
            if remaining[i] and (u == v or w == v):
                remaining[i] = False
                visit(w if u == v else u)
        result.append(v)

    visit(start)
    if any(remaining):
        return 0, b""
    payload = b"".join(struct.pack("<q", v) for v in reversed(result))
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload

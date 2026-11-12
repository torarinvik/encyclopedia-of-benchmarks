"""Independent graph oracle for SL(2, F) potential union-find."""

from collections import deque
import struct

MOD = 998_244_353
MAX_N = 32
MAX_Q = 64
MAX_PARSEABLE_INPUT_LENGTH = 2 + 7 * MAX_Q
MAX_OUTPUT_BYTES = 32 * MAX_Q
IDENTITY = (1, 0, 0, 1)


def _multiply(left, right):
    a, b, c, d = left
    e, f, g, h = right
    return ((a * e + b * g) % MOD,
            (a * f + b * h) % MOD,
            (c * e + d * g) % MOD,
            (c * f + d * h) % MOD)


def _inverse(matrix):
    a, b, c, d = matrix
    return (d, (-b) % MOD, (-c) % MOD, a)


def _relative(graph, start, target):
    """Return inverse(a_start)*a_target along an accepted equation path."""
    products = {start: IDENTITY}
    pending = deque([start])
    while pending:
        node = pending.popleft()
        if node == target:
            return products[node]
        for neighbor, factor in graph[node]:
            if neighbor not in products:
                products[neighbor] = _multiply(products[node], factor)
                pending.append(neighbor)
    return None


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for fixed-width matrix operation records."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or len(values) < 2):
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return -1, b""
    if len(values) != 2 + 7 * q:
        return -1, b""

    operations = []
    for offset in range(2, len(values), 7):
        kind, u, v = values[offset:offset + 3]
        matrix = tuple(values[offset + 3:offset + 7])
        if not 0 <= u < n or not 0 <= v < n:
            return -1, b""
        if kind == 0:
            if any(not 0 <= entry < MOD for entry in matrix):
                return -1, b""
            a, b, c, d = matrix
            if (a * d - b * c) % MOD != 1:
                return -1, b""
        elif kind == 1:
            if matrix != (0, 0, 0, 0):
                return -1, b""
        else:
            return -1, b""
        operations.append((kind, u, v, matrix))

    required = 32 * q
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""

    graph = [[] for _ in range(n)]
    answers = []
    for kind, u, v, matrix in operations:
        if kind == 0:
            known = _relative(graph, v, u)
            if known is None:
                inverse = _inverse(matrix)
                graph[v].append((u, matrix))
                graph[u].append((v, inverse))
                answers.append((1, 0, 0, 0))
            else:
                answers.append((int(known == matrix), 0, 0, 0))
        else:
            relative = _relative(graph, v, u)
            answers.append((-1, -1, -1, -1) if relative is None else relative)

    output = b"".join(struct.pack("<q", value) for row in answers for value in row)
    return len(output), output

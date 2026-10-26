"""Independent repeated-minimum verifier for GBBS Goodrich--Pszona ordering."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_NODES = 20
MAX_EDGES = 190
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or values is not None and (not isinstance(values, (tuple, list))
                                       or len(values) > MAX_INPUT_LENGTH
                                       or any(type(x) is not int or not I64_MIN <= x <= I64_MAX
                                              for x in values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None or len(values) < 2:
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return INVALID_RESULT, b""
    adjacency = [[False] * n for _ in range(n)]
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or adjacency[u][v]:
            return INVALID_RESULT, b""
        adjacency[u][v] = adjacency[v][u] = True
    if output_is_null or capacity is not None and capacity < 8 * n:
        return OUTPUT_ERROR, b""

    degrees = [sum(row) for row in adjacency]
    alive = [True] * n
    ranks = [-1] * n
    for position in range(n):
        chosen = -1
        for vertex in range(n):
            if alive[vertex] and (chosen < 0 or degrees[vertex] < degrees[chosen]):
                chosen = vertex
        # Ascending scan preserves the lowest vertex ID on a tie.
        ranks[chosen] = position
        alive[chosen] = False
        for neighbor in range(n):
            if alive[neighbor] and adjacency[chosen][neighbor]:
                degrees[neighbor] -= 1
    output = b"".join(struct.pack("<q", value) for value in ranks)
    return len(output), output


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    return expected_output(values)

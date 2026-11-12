"""Independent adjacency-matrix verifier for dynamic edge-side sums."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_Q = 64
MAX_VALUE = 1_000
MAX_VALID_INPUT_LENGTH = 3 * MAX_N + 5 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > 3 * MAX_N + 5 * MAX_Q + 1
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 3 * n + 5 * q:
        return None
    weights = list(values[2:2 + n])
    if any(not 0 <= x <= MAX_VALUE for x in weights):
        return None
    adjacency = [[False] * n for _ in range(n)]
    at = 2 + n
    for _ in range(n - 1):
        u, v = values[at], values[at + 1]
        at += 2
        if not (0 <= u < n and 0 <= v < n and u != v) or adjacency[u][v]:
            return None
        adjacency[u][v] = adjacency[v][u] = True
    # The N-1-edge input is a tree exactly when every vertex is reachable.
    reached = {0}
    frontier = [0]
    for u in frontier:
        for v, linked in enumerate(adjacency[u]):
            if linked and v not in reached:
                reached.add(v)
                frontier.append(v)
    if len(reached) != n:
        return None
    return n, q, weights, adjacency, at


def _answers(values, n, q, weights, adjacency, operation_start):
    output = []
    for i in range(q):
        at = operation_start + i * 5
        kind, a, b, c, d = values[at:at + 5]
        if kind == 0:
            if not (0 <= a < n and 0 <= b < n and 0 <= c < n and 0 <= d < n
                    and a != b and c != d and adjacency[a][b]):
                return None
            adjacency[a][b] = adjacency[b][a] = False
            if adjacency[c][d]:
                return None
            # The replacement endpoints must lie in distinct components.
            stack = [c]
            seen = {c}
            for u in stack:
                for v, linked in enumerate(adjacency[u]):
                    if linked and v not in seen:
                        seen.add(v)
                        stack.append(v)
            if d in seen:
                return None
            adjacency[c][d] = adjacency[d][c] = True
        elif kind == 1:
            if not (0 <= a < n and 0 <= b <= MAX_VALUE and c == 0 and d == 0):
                return None
            weights[a] += b
        elif kind == 2:
            if not (0 <= a < n and 0 <= b < n and c == 0 and d == 0
                    and adjacency[a][b]):
                return None
            stack = [a]
            seen = {a}
            total = 0
            for u in stack:
                total += weights[u]
                for v, linked in enumerate(adjacency[u]):
                    if ((u == a and v == b) or (u == b and v == a)
                            or not linked or v in seen):
                        continue
                    seen.add(v)
                    stack.append(v)
            output.append(total)
        else:
            return None
    return output


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    expected_result, expected = expected_output(
        values,
        output_capacity=output_capacity,
        output_is_null=output_is_null,
        input_is_null=input_is_null,
        input_length=input_length,
    )
    return result == expected_result and output == expected


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, q, weights, adjacency, operation_start = parsed
    answers = _answers(values, n, q, weights, adjacency, operation_start)
    if answers is None:
        return -1, b""
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(capacity) is not int or capacity < 0:
        return -2, b""
    required = 8 * len(answers)
    if required and (output_is_null or capacity < required):
        return -2, b""
    expected = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(expected), expected

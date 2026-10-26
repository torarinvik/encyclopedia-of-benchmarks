"""Independent matrix-quotient verifier for bounded GraphAIBench HAC."""

from __future__ import annotations

import struct

MAX_N = 8
MAX_M = 24
MAX_INPUT = 2 + 3 * MAX_M
MAX_WEIGHT = 32
ROOT_PARENT = (1 << 32) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT
            or any(type(item) is not int or not I64_MIN <= item <= I64_MAX
                   for item in values)):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 3 * m:
        return None

    # The verifier validates the original graph using a separate dense matrix.
    matrix = [[0] * (2 * MAX_N - 1) for _ in range(2 * MAX_N - 1)]
    weight_seen = set()
    for pos in range(2, len(values), 3):
        u, v, weight = values[pos:pos + 3]
        if not (0 <= u < v < n and 1 <= weight <= MAX_WEIGHT):
            return None
        if matrix[u][v] or weight in weight_seen:
            return None
        matrix[u][v] = matrix[v][u] = weight
        weight_seen.add(weight)

    if n > 1:
        reached = {0}
        pending = [0]
        while pending:
            current = pending.pop()
            for neighbor in range(n):
                if matrix[current][neighbor] and neighbor not in reached:
                    reached.add(neighbor)
                    pending.append(neighbor)
        if len(reached) != n:
            return None
    return n, matrix


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""

    n, quotient = parsed
    parent = [ROOT_PARENT] * (2 * n - 1)
    merge_level = [0] * (2 * n - 1)
    active = list(range(n))

    # Each round picks the largest active quotient edge, then forms the
    # complete-linkage quotient row by taking min on shared neighbors and
    # preserving a one-sided similarity. This is independent of the package
    # oracle's set-of-original-vertices representation.
    for round_index in range(n - 1):
        winner = None
        for left_pos in range(len(active)):
            left = active[left_pos]
            for right_pos in range(left_pos + 1, len(active)):
                right = active[right_pos]
                weight = quotient[left][right]
                if weight and (winner is None or weight > winner[2]):
                    winner = (left, right, weight)
        if winner is None:
            return INVALID_RESULT, b""

        left, right, level = winner
        new_node = n + round_index
        parent[left] = parent[right] = new_node
        merge_level[left] = merge_level[right] = level
        for neighbor in active:
            if neighbor == left or neighbor == right:
                continue
            left_weight = quotient[left][neighbor]
            right_weight = quotient[right][neighbor]
            if left_weight and right_weight:
                combined = min(left_weight, right_weight)
            else:
                combined = left_weight or right_weight
            quotient[new_node][neighbor] = quotient[neighbor][new_node] = combined
            quotient[left][neighbor] = quotient[neighbor][left] = 0
            quotient[right][neighbor] = quotient[neighbor][right] = 0
        active = [node for node in active if node != left and node != right]
        active.append(new_node)

    encoded = b"".join(struct.pack("<qq", parent[i], merge_level[i])
                       for i in range(2 * n - 1))
    if output_is_null or capacity is not None and capacity < len(encoded):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded

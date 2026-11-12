"""Bottom-up bitmask-DP oracle for a bounded weighted general graph."""

from __future__ import annotations

import struct

MAX_N = 16
MAX_WEIGHT = 1_000_000
MAX_EDGES = MAX_N * (MAX_N - 1) // 2
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 2 + 2 * (MAX_N // 2)
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS


def _parse(values, input_is_null, input_length):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or len(values) < 2):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= n * (n - 1) // 2:
        return None
    if len(values) != 2 + 3 * m:
        return None
    weights = [[0] * n for _ in range(n)]
    neighbors = [[] for _ in range(n)]
    seen = set()
    cursor = 2
    for _ in range(m):
        u, v, weight = values[cursor:cursor + 3]
        cursor += 3
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 1 <= weight <= MAX_WEIGHT):
            return None
        edge = (min(u, v), max(u, v))
        if edge in seen:
            return None
        seen.add(edge)
        u, v = edge
        weights[u][v] = weights[v][u] = weight
        neighbors[u].append(v)
        neighbors[v].append(u)
    for row in neighbors:
        row.sort()
    return n, weights, neighbors


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ABI result and bytes for the maximum-weight matching certificate."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, weights, neighbors = parsed

    state_count = 1 << n
    best = [0] * state_count
    choice = [-1] * state_count
    for mask in range(1, state_count):
        bit = mask & -mask
        vertex = bit.bit_length() - 1
        remainder = mask ^ bit
        optimum = best[remainder]
        partner = -1
        for other in neighbors[vertex]:
            other_bit = 1 << other
            if remainder & other_bit:
                candidate = weights[vertex][other] + best[remainder ^ other_bit]
                if candidate > optimum:
                    optimum = candidate
                    partner = other
        best[mask] = optimum
        choice[mask] = partner

    pairs = []
    mask = state_count - 1
    while mask:
        bit = mask & -mask
        vertex = bit.bit_length() - 1
        partner = choice[mask]
        if partner < 0:
            mask ^= bit
        else:
            pairs.extend((vertex, partner))
            mask ^= bit | (1 << partner)
    words = [len(pairs) // 2, best[-1], *pairs]
    output = b"".join(struct.pack("<q", word) for word in words)

    effective_capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < len(output):
        return -2, b""
    return len(output), output

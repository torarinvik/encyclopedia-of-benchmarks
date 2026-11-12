"""Independent subset-DP optimum and certificate checker for rooted orders."""

from __future__ import annotations

import struct

MAX_N = 12
MAX_WEIGHT = 1_000_000
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)


def parse_input(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 3 <= input_length <= 3 * MAX_N + 1):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 3 * n:
        return None
    parents = [-1] + list(values[1:n])
    if any(not 0 <= parents[v] < v for v in range(1, n)):
        return None
    c_values = list(values[n:2 * n])
    d_values = list(values[2 * n:3 * n])
    if any(not 0 <= x <= MAX_WEIGHT for x in c_values + d_values):
        return None
    if sum(c_values) > MAX_WEIGHT or sum(d_values) > MAX_WEIGHT:
        return None
    return n, parents, c_values, d_values


def minimum_objective(n, parents, c_values, d_values):
    state_count = 1 << n
    total_d = [0] * state_count
    for mask in range(1, state_count):
        bit = mask & -mask
        vertex = bit.bit_length() - 1
        total_d[mask] = total_d[mask ^ bit] + d_values[vertex]
    infinity = 1 << 120
    best = [infinity] * state_count
    best[0] = 0
    for mask in range(state_count):
        if best[mask] == infinity:
            continue
        for vertex in range(n):
            bit = 1 << vertex
            if mask & bit:
                continue
            if vertex != 0 and not (mask & (1 << parents[vertex])):
                continue
            next_mask = mask | bit
            candidate = best[mask] + c_values[vertex] * total_d[mask]
            if candidate < best[next_mask]:
                best[next_mask] = candidate
    return best[-1]


def verify_certificate(values, result, output, output_capacity=None,
                       output_is_null=False, input_is_null=False,
                       input_length=None):
    parsed = parse_input(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and output == b""
    n, parents, c_values, d_values = parsed
    required_bytes = 8 * (n + 1)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0):
        return result == -2 and output == b""
    if output_is_null or capacity < required_bytes:
        return result == -2 and output == b""
    if not isinstance(output, (bytes, bytearray)):
        return False
    if result != len(output) or result != required_bytes:
        return False
    try:
        words = struct.unpack("<" + "q" * (n + 1), output)
    except struct.error:
        return False
    objective, order = words[0], list(words[1:])
    if sorted(order) != list(range(n)):
        return False
    position = [0] * n
    for index, vertex in enumerate(order):
        position[vertex] = index
    for vertex in range(1, n):
        if position[parents[vertex]] >= position[vertex]:
            return False
    measured = 0
    prefix_d = 0
    for vertex in order:
        measured += c_values[vertex] * prefix_d
        prefix_d += d_values[vertex]
    if objective != measured:
        return False
    return objective == minimum_objective(n, parents, c_values, d_values)


def verify_result(values, result, output, **abi_options):
    return verify_certificate(values, result, output, **abi_options)

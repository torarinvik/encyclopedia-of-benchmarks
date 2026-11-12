"""Independent recursive matching enumerator for bounded graph profiles."""

from __future__ import annotations

from functools import lru_cache
import struct

MAX_N = 16
MAX_WEIGHT = 1_000_000
MAX_OUTPUT_BYTES = 8 * (2 + 2 * (MAX_N // 2))


def _parse_graph(values, input_is_null, input_length):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > 2 + 3 * (MAX_N * (MAX_N - 1) // 2) + 1
            or input_length != len(values) or len(values) < 2):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    vertex_count, edge_count = values[0], values[1]
    if (not 1 <= vertex_count <= MAX_N
            or not 0 <= edge_count <= vertex_count * (vertex_count - 1) // 2
            or len(values) != 2 + 3 * edge_count):
        return None
    graph = [dict() for _ in range(vertex_count)]
    seen_edges = set()
    offset = 2
    for _ in range(edge_count):
        left, right, weight = values[offset:offset + 3]
        offset += 3
        if (not 0 <= left < vertex_count or not 0 <= right < vertex_count
                or left == right or not 1 <= weight <= MAX_WEIGHT):
            return None
        pair = (min(left, right), max(left, right))
        if pair in seen_edges:
            return None
        seen_edges.add(pair)
        graph[left][right] = weight
        graph[right][left] = weight
    return vertex_count, graph


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return the best matching by recursive unmatched-or-paired enumeration."""
    parsed = _parse_graph(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, graph = parsed

    @lru_cache(maxsize=None)
    def enumerate_matchings(mask):
        if mask == 0:
            return 0, ()
        least_bit = mask & -mask
        vertex = least_bit.bit_length() - 1
        remaining = mask ^ least_bit
        best_weight, best_pairs = enumerate_matchings(remaining)
        for partner in sorted(graph[vertex]):
            partner_bit = 1 << partner
            if remaining & partner_bit:
                sub_weight, sub_pairs = enumerate_matchings(remaining ^ partner_bit)
                candidate_weight = graph[vertex][partner] + sub_weight
                if candidate_weight > best_weight:
                    best_weight = candidate_weight
                    best_pairs = ((vertex, partner),) + sub_pairs
        return best_weight, best_pairs

    total_weight, pairs = enumerate_matchings((1 << n) - 1)
    words = [len(pairs), total_weight]
    for left, right in pairs:
        words.extend((left, right))
    payload = b"".join(struct.pack("<q", word) for word in words)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(capacity) is not int or capacity < 0:
        return -2, b""
    if output_is_null or capacity < len(payload):
        return -2, b""
    return len(payload), payload


def verify_result(values, result, output, **abi_options):
    """Compare the supplied ABI result with recursive exhaustive enumeration."""
    return (result, output) == expected_output(values, **abi_options)

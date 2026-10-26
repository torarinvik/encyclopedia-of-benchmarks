"""Independent round-based verifier for GBBS maximal matching."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES
OUTPUT_BYTES = 8 * MAX_EDGES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(item) is not int or not I64_MIN <= item <= I64_MAX
                   for item in values)):
        return INVALID_RESULT, b""
    node_count, edge_count = values[:2]
    if (not 1 <= node_count <= MAX_NODES or not 0 <= edge_count <= MAX_EDGES
            or len(values) != 2 + 3 * edge_count):
        return INVALID_RESULT, b""
    ranks = values[2:2 + edge_count]
    if sorted(ranks) != list(range(edge_count)):
        return INVALID_RESULT, b""
    edges = []
    adjacency = [[False] * node_count for _ in range(node_count)]
    position = 2 + edge_count
    for edge_id in range(edge_count):
        left, right = values[position + 2 * edge_id:position + 2 * edge_id + 2]
        if not 0 <= left < right < node_count or adjacency[left][right]:
            return INVALID_RESULT, b""
        adjacency[left][right] = adjacency[right][left] = True
        edges.append((left, right))

    output_bytes = edge_count * 8
    if output_is_null or capacity is not None and capacity < output_bytes:
        return OUTPUT_ERROR, b""

    # Simulate source-style rounds by selecting every live edge with no
    # higher-ranked live edge at either endpoint.
    live = [True] * edge_count
    used = [False] * node_count
    chosen = [0] * edge_count
    while any(live):
        round_edges = []
        for edge_id, (left, right) in enumerate(edges):
            if not live[edge_id]:
                continue
            rank = ranks[edge_id]
            dominated = False
            for other_id, (other_left, other_right) in enumerate(edges):
                if (live[other_id] and other_id != edge_id
                and rank > ranks[other_id]
                        and (left == other_left or left == other_right
                             or right == other_left or right == other_right)):
                    dominated = True
                    break
            if not dominated:
                round_edges.append(edge_id)
        if not round_edges:
            return INVALID_RESULT, b""
        for edge_id in round_edges:
            left, right = edges[edge_id]
            if used[left] or used[right]:
                return INVALID_RESULT, b""
            chosen[edge_id] = 1
            used[left] = used[right] = True
            live[edge_id] = False
        for edge_id, (left, right) in enumerate(edges):
            if live[edge_id] and (used[left] or used[right]):
                live[edge_id] = False
    if any(not (used[left] or used[right]) for left, right in edges):
        return INVALID_RESULT, b""
    encoded = b"".join(struct.pack("<q", value) for value in chosen)
    return output_bytes, encoded

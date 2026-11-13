"""Exhaustive bounded oracle for the strictly heavier second-best MST."""

from itertools import combinations
import struct

MAX_N = 8
MAX_M = 20
MAX_WEIGHT = 1_000_000
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_OUTPUT_BYTES = 32


def _parse(values, input_length=None):
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not n - 1 <= m <= MAX_M:
        return None
    if len(values) != 2 + 3 * m:
        return None
    edges = []
    seen = set()
    for edge_id, offset in enumerate(range(2, len(values), 3)):
        u, v, weight = values[offset:offset + 3]
        if not (0 <= u < v < n and 0 <= weight <= MAX_WEIGHT):
            return None
        if (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v, weight, edge_id))
    if not _is_connected(n, edges):
        return None
    return n, edges


def _is_connected(n, edges):
    parent = list(range(n))

    def find(vertex):
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for u, v, _weight, _edge_id in edges:
        root_u, root_v = find(u), find(v)
        if root_u != root_v:
            parent[root_v] = root_u
    return len({find(vertex) for vertex in range(n)}) == 1


def _is_tree(n, edges):
    if n == 1:
        return not edges
    if len(edges) != n - 1:
        return False
    parent = list(range(n))

    def find(vertex):
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    for u, v, _weight, _edge_id in edges:
        root_u = find(u)
        root_v = find(v)
        if root_u == root_v:
            return False
        parent[root_v] = root_u
    return len({find(vertex) for vertex in range(n)}) == 1


def _canonical_mst(n, edges):
    parent = list(range(n))

    def find(vertex):
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    selected = []
    total = 0
    for edge in sorted(edges, key=lambda edge: (edge[2], edge[3])):
        u, v, weight, edge_id = edge
        root_u = find(u)
        root_v = find(v)
        if root_u != root_v:
            parent[root_v] = root_u
            selected.append(edge_id)
            total += weight
    return selected, total


def _pack(values):
    return b"".join(struct.pack("<q", value) for value in values)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null:
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    mst_ids, mst_weight = _canonical_mst(n, edges)

    # Enumerate every (N-1)-edge subset and test it directly as a tree.
    second_weight = None
    for ids in combinations(range(len(edges)), n - 1):
        chosen = [edges[edge_id] for edge_id in ids]
        if not _is_tree(n, chosen):
            continue
        weight = sum(edge[2] for edge in chosen)
        if weight > mst_weight and (second_weight is None or weight < second_weight):
            second_weight = weight

    added_id = removed_id = -1
    if second_weight is not None:
        mst_set = set(mst_ids)
        # Pick the first canonical one-edge exchange attaining the exhaustive
        # second-best weight. The production ports find it by tree-path maxima.
        for candidate_add in range(len(edges)):
            if candidate_add in mst_set:
                continue
            for candidate_remove in sorted(mst_ids):
                exchanged = [edges[edge_id] for edge_id in mst_ids
                             if edge_id != candidate_remove]
                exchanged.append(edges[candidate_add])
                if (sum(edge[2] for edge in exchanged) == second_weight
                        and _is_tree(n, exchanged)):
                    added_id, removed_id = candidate_add, candidate_remove
                    break
            if added_id >= 0:
                break
        if added_id < 0:
            return -1, b""

    result_values = (mst_weight, -1 if second_weight is None else second_weight,
                     added_id, removed_id)
    payload = _pack(result_values)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return MAX_OUTPUT_BYTES, payload


def validate_output(values, output):
    """Check the returned one-edge exchange against the exhaustive optimum."""
    parsed = _parse(values)
    if parsed is None or len(output) != MAX_OUTPUT_BYTES:
        return False
    n, edges = parsed
    expected_result, expected = expected_output(values, MAX_OUTPUT_BYTES)
    if expected_result != MAX_OUTPUT_BYTES or output != expected:
        return False
    mst_ids, mst_weight = _canonical_mst(n, edges)
    reported_mst, reported_second, added_id, removed_id = struct.unpack("<4q", output)
    if reported_mst != mst_weight:
        return False
    if reported_second == -1:
        return added_id == -1 and removed_id == -1
    if (not 0 <= added_id < len(edges) or not 0 <= removed_id < len(edges)
            or added_id in mst_ids or removed_id not in mst_ids):
        return False
    exchanged = [edges[edge_id] for edge_id in mst_ids if edge_id != removed_id]
    exchanged.append(edges[added_id])
    return (_is_tree(n, exchanged)
            and sum(edge[2] for edge in exchanged) == reported_second
            and reported_second > reported_mst)

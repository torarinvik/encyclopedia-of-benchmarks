"""Two-scan overlap-forest component labels for signed permutations."""
from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "signed_permutation_overlap_forest_components"
MAX_N = 8
MAX_VALID_INPUT_LENGTH = 1 + MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_CYCLES = MAX_N + 1
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_CYCLES)
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None, length: int | None,
           is_null: bool) -> list[int] | None:
    if (type(is_null) is not bool or is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    actual = len(values) if length is None else length
    if type(actual) is not int or actual != len(values):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or actual != n + 1:
        return None
    seen = [False] * (n + 1)
    result = list(values[1:])
    for gene in result:
        if gene == 0 or abs(gene) > n or seen[abs(gene)]:
            return None
        seen[abs(gene)] = True
    return result


def _cycles(signed: list[int]) -> tuple[list[int], list[int], list[list[tuple[int, int]]]]:
    n = len(signed)
    size = 2 * n + 2
    permutation = [0] * size
    permutation[-1] = size - 1
    for index, gene in enumerate(signed):
        first, second = 2 * abs(gene) - 1, 2 * abs(gene)
        if gene < 0:
            first, second = second, first
        permutation[2 * index + 1] = first
        permutation[2 * index + 2] = second

    black = [vertex ^ 1 for vertex in range(size)]
    gray = [-1] * size
    for pair in range(n + 1):
        left, right = permutation[2 * pair], permutation[2 * pair + 1]
        gray[left], gray[right] = right, left

    cycle_of = [-1] * size
    begins: list[int] = []
    ends: list[int] = []
    for start in range(size):
        if cycle_of[start] >= 0:
            continue
        cid = len(begins)
        vertex = start
        cycle_vertices: list[int] = []
        while cycle_of[vertex] < 0:
            cycle_of[vertex] = cid
            cycle_vertices.append(vertex)
            vertex = gray[black[vertex]]
        begins.append(min(cycle_vertices))
        ends.append(max(cycle_vertices))

    gray_edges: list[list[tuple[int, int]]] = [[] for _ in begins]
    for pair in range(n + 1):
        left, right = permutation[2 * pair], permutation[2 * pair + 1]
        gray_edges[cycle_of[left]].append((left, right))
    return begins, ends, gray_edges


def _forest_labels(signed: list[int]) -> list[int]:
    begins, ends, _ = _cycles(signed)
    n = len(signed)
    size = 2 * n + 2
    permutation = [0] * size
    permutation[-1] = size - 1
    for index, gene in enumerate(signed):
        first, second = 2 * abs(gene) - 1, 2 * abs(gene)
        if gene < 0:
            first, second = second, first
        permutation[2 * index + 1], permutation[2 * index + 2] = first, second
    black = [vertex ^ 1 for vertex in range(size)]
    gray = [-1] * size
    for pair in range(n + 1):
        left, right = permutation[2 * pair], permutation[2 * pair + 1]
        gray[left], gray[right] = right, left
    cycle_of_vertex = [-1] * size
    for cid, begin in enumerate(begins):
        vertex = begin
        while cycle_of_vertex[vertex] < 0:
            cycle_of_vertex[vertex] = cid
            vertex = gray[black[vertex]]

    parent = list(range(len(begins)))
    stack: list[list[int]] = []  # [cycle id, active subtree begin, active subtree end]
    for vertex in range(size):
        cid = cycle_of_vertex[vertex]
        begin, end = begins[cid], ends[cid]
        if vertex == begin:
            stack.append([cid, begin, end])
        extent_begin, extent_end = begin, end
        while stack and stack[-1][1] > begin:
            popped = stack.pop()
            extent_begin = min(extent_begin, popped[1])
            extent_end = max(extent_end, popped[2])
            parent[popped[0]] = cid
        if not stack:
            return []
        stack[-1][1] = min(extent_begin, stack[-1][1])
        stack[-1][2] = max(extent_end, stack[-1][2])
        if vertex == stack[-1][2]:
            stack.pop()

    component = [0] * len(begins)
    for cid in range(len(begins)):
        component[cid] = cid if parent[cid] == cid else component[parent[cid]]
    return [begins[root] for root in component]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    signed = _parse(values, input_length, input_is_null)
    if signed is None:
        return -1, b""
    begins, ends, _ = _cycles(signed)
    roots = _forest_labels(signed)
    result = [len(begins)]
    for begin, end, root in zip(begins, ends, roots):
        result.extend((begin, end, root))
    payload = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

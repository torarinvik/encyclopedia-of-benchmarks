"""Explicit overlap-graph reference for Bader's overlap-forest profile."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 1 + MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_CYCLES = MAX_N + 1
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_CYCLES)
WORKSPACE_BYTES = 4096


def _valid(values: Sequence[int] | None, length: int | None,
           is_null: bool) -> list[int] | None:
    if (type(is_null) is not bool or is_null
            or type(values) not in (list, tuple)
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values)):
        return None
    count = len(values) if length is None else length
    if type(count) is not int or count != len(values):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or count != n + 1:
        return None
    seen = set()
    signed = list(values[1:])
    for gene in signed:
        if gene == 0 or abs(gene) > n or abs(gene) in seen:
            return None
        seen.add(abs(gene))
    return signed


def _cycle_lists(signed: list[int]) -> tuple[list[tuple[int, int]], list[list[tuple[int, int]]]]:
    n = len(signed)
    permutation = [0, *([0] * (2 * n)), 2 * n + 1]
    for position, gene in enumerate(signed):
        pair = (2 * abs(gene) - 1, 2 * abs(gene))
        if gene < 0:
            pair = pair[::-1]
        permutation[1 + 2 * position:3 + 2 * position] = pair
    gray_partner = [-1] * len(permutation)
    for pair_index in range(n + 1):
        a, b = permutation[2 * pair_index:2 * pair_index + 2]
        gray_partner[a] = b
        gray_partner[b] = a

    assigned = [False] * len(permutation)
    cycles: list[tuple[int, int]] = []
    gray_edges_by_cycle: list[list[tuple[int, int]]] = []
    cycle_for_vertex = [-1] * len(permutation)
    for seed in range(len(permutation)):
        if assigned[seed]:
            continue
        vertices = []
        vertex = seed
        while not assigned[vertex]:
            assigned[vertex] = True
            vertices.append(vertex)
            vertex = gray_partner[vertex ^ 1]
        cid = len(cycles)
        for item in vertices:
            cycle_for_vertex[item] = cid
        cycles.append((min(vertices), max(vertices)))
        gray_edges_by_cycle.append([])
    for pair_index in range(n + 1):
        edge = tuple(permutation[2 * pair_index:2 * pair_index + 2])
        gray_edges_by_cycle[cycle_for_vertex[edge[0]]].append(edge)
    return cycles, gray_edges_by_cycle


def _crosses(first: tuple[int, int], second: tuple[int, int]) -> bool:
    a, b = sorted(first)
    c, d = sorted(second)
    return (a < c < b < d) or (c < a < d < b)


def _graph_labels(cycles: list[tuple[int, int]],
                  edges: list[list[tuple[int, int]]]) -> list[int]:
    adjacency = [set() for _ in cycles]
    for left in range(len(cycles)):
        for right in range(left + 1, len(cycles)):
            if any(_crosses(a, b) for a in edges[left] for b in edges[right]):
                adjacency[left].add(right)
                adjacency[right].add(left)
    roots = [-1] * len(cycles)
    for start in range(len(cycles)):
        if roots[start] >= 0:
            continue
        members = []
        queue = [start]
        roots[start] = start
        while queue:
            vertex = queue.pop()
            members.append(vertex)
            for neighbor in adjacency[vertex]:
                if roots[neighbor] < 0:
                    roots[neighbor] = start
                    queue.append(neighbor)
        canonical = min(members, key=lambda cid: cycles[cid][0])
        for cid in members:
            roots[cid] = canonical
    return [cycles[root][0] for root in roots]


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
    signed = _valid(values, input_length, input_is_null)
    if signed is None:
        return -1, b""
    cycles, edges = _cycle_lists(signed)
    roots = _graph_labels(cycles, edges)
    result = [len(cycles)]
    for (begin, end), root in zip(cycles, roots):
        result.extend((begin, end, root))
    payload = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

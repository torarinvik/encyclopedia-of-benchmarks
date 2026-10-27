"""Bounded oracle for DOI 376's rebuild-after-update reachability baseline."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 8
MAX_INITIAL_EDGES = 16
MAX_OPERATIONS = 20
MAX_INPUT_LENGTH = 97
MAX_OUTPUT_BYTES = 168
MAX_WORKSPACE_BYTES = 2048


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, source, edge_count = values[:3]
    if not 2 <= n <= MAX_N or not 0 <= source < n or not 0 <= edge_count <= MAX_INITIAL_EDGES:
        return None
    cursor = 3
    edges = []
    edge_set = set()
    for _ in range(edge_count):
        u, v = values[cursor:cursor + 2]
        cursor += 2
        if not 0 <= u < n or not 0 <= v < n or (u, v) in edge_set:
            return None
        edge_set.add((u, v))
        edges.append((u, v))
    if cursor >= len(values):
        return None
    operation_count = values[cursor]
    cursor += 1
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != cursor + 3 * operation_count:
        return None
    operations = []
    for _ in range(operation_count):
        kind, u, v = values[cursor:cursor + 3]
        cursor += 3
        if kind in (0, 1):
            if not 0 <= u < n or not 0 <= v < n:
                return None
        elif kind == 2:
            if not 0 <= u < n or v != 0:
                return None
        else:
            return None
        operations.append((kind, u, v))
    return n, source, edges, operations


def _reachable(n: int, source: int, adjacency: list[list[bool]]) -> list[bool]:
    seen = [False] * n
    seen[source] = True
    queue = deque([source])
    while queue:
        u = queue.popleft()
        for v in range(n):
            if adjacency[u][v] and not seen[v]:
                seen[v] = True
                queue.append(v)
    return seen


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, source, edges, operations = parsed
    adjacency = [[False] * n for _ in range(n)]
    for u, v in edges:
        adjacency[u][v] = True
    reachable = _reachable(n, source, adjacency)
    answers = []
    for kind, u, v in operations:
        if kind == 0:
            adjacency[u][v] = True
            reachable = _reachable(n, source, adjacency)
        elif kind == 1:
            adjacency[u][v] = False
            reachable = _reachable(n, source, adjacency)
        else:
            answers.append(int(reachable[u]))
    payload_values = [len(answers), *answers]
    payload = struct.pack("<" + "q" * len(payload_values), *payload_values)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

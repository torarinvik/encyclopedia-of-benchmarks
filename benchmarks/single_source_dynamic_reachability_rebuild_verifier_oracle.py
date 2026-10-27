"""Independent query-time BFS verifier for DOI 376 reachability traces."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 8
MAX_INITIAL_EDGES = 16
MAX_OPERATIONS = 20
MAX_INPUT_LENGTH = 97


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return None
    n, source, m = values[0], values[1], values[2]
    if not 2 <= n <= MAX_N or not 0 <= source < n or not 0 <= m <= MAX_INITIAL_EDGES:
        return None
    p = 3
    graph = [[False] * n for _ in range(n)]
    for _ in range(m):
        u, v = values[p], values[p + 1]
        p += 2
        if not (0 <= u < n and 0 <= v < n) or graph[u][v]:
            return None
        graph[u][v] = True
    if p == len(values):
        return None
    q = values[p]
    p += 1
    if not 0 <= q <= MAX_OPERATIONS or len(values) != p + 3 * q:
        return None
    ops = []
    for _ in range(q):
        op, a, b = values[p:p + 3]
        p += 3
        if op in (0, 1):
            if not (0 <= a < n and 0 <= b < n):
                return None
        elif op == 2:
            if not (0 <= a < n and b == 0):
                return None
        else:
            return None
        ops.append((op, a, b))
    return n, source, graph, ops


def _reachable(graph: list[list[bool]], source: int, target: int) -> bool:
    seen = {source}
    queue = deque([source])
    while queue:
        u = queue.popleft()
        if u == target:
            return True
        for v, present in enumerate(graph[u]):
            if present and v not in seen:
                seen.add(v)
                queue.append(v)
    return False


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
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, source, graph, ops = decoded
    del n
    answers = []
    for op, a, b in ops:
        if op == 0:
            graph[a][b] = True
        elif op == 1:
            graph[a][b] = False
        else:
            answers.append(int(_reachable(graph, source, a)))
    packed = [len(answers), *answers]
    payload = struct.pack("<" + "q" * len(packed), *packed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

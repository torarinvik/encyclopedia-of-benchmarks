"""Adjacency-forest reference and route-certificate serializer."""
from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_CUSTOMERS = 7
MAX_CAPACITY = 100
MAX_DISTANCE = 1000
MAX_VALID_INPUT_LENGTH = 2 + MAX_CUSTOMERS + (MAX_CUSTOMERS + 1) ** 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 120
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    n, capacity = values[:2]
    if not 0 <= n <= MAX_CUSTOMERS or not 1 <= capacity <= MAX_CAPACITY:
        return None
    width = n + 1
    if len(values) != 2 + n + width * width:
        return None
    demand = [0, *values[2:2 + n]]
    if any(type(q) is not int or not 1 <= q <= capacity for q in demand[1:]):
        return None
    raw = values[2 + n:]
    d = [[raw[r * width + c] for c in range(width)] for r in range(width)]
    if any(type(x) is not int or x < 0 or x > MAX_DISTANCE for row in d for x in row):
        return None
    if any(d[v][v] != 0 for v in range(width)):
        return None
    for a in range(width):
        for b in range(a + 1, width):
            if d[a][b] != d[b][a]:
                return None
    return n, capacity, demand, d


def _components(adjacency: list[set[int]], start: int) -> list[int]:
    component: list[int] = []
    queue = deque([start])
    seen = {start}
    while queue:
        vertex = queue.popleft()
        component.append(vertex)
        for neighbor in adjacency[vertex]:
            if neighbor not in seen:
                seen.add(neighbor)
                queue.append(neighbor)
    return component


def _path(adjacency: list[set[int]], component: list[int]) -> list[int]:
    ends = sorted(v for v in component if len(adjacency[v]) <= 1)
    start = ends[0]
    order: list[int] = []
    previous = 0
    current = start
    while current:
        order.append(current)
        following = [v for v in adjacency[current] if v != previous]
        if not following:
            break
        previous, current = current, following[0]
    reverse = list(reversed(order))
    return min(order, reverse)


def _words(n: int, cap: int, demand: list[int], d: list[list[int]]) -> list[int]:
    adjacency = [set() for _ in range(n + 1)]
    savings = sorted(
        ((d[0][i] + d[0][j] - d[i][j], i, j)
         for i in range(1, n + 1) for j in range(i + 1, n + 1)),
        key=lambda record: (-record[0], record[1], record[2]),
    )
    for saving, a, b in savings:
        if saving <= 0:
            break
        left = _components(adjacency, a)
        if b in left:
            continue
        right = _components(adjacency, b)
        if (len(adjacency[a]) >= 2 or len(adjacency[b]) >= 2
                or sum(demand[v] for v in left + right) > cap):
            continue
        adjacency[a].add(b)
        adjacency[b].add(a)

    routes: list[list[int]] = []
    unseen = set(range(1, n + 1))
    while unseen:
        component = _components(adjacency, min(unseen))
        unseen.difference_update(component)
        routes.append(_path(adjacency, component))
    routes.sort()
    result = [len(routes)]
    for route in routes:
        result.extend((len(route), *route))
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int
             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", x) for x in _words(*parsed))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]

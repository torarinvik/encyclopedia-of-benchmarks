"""Independent bounded oracle for SAGA-Bench insertion-only updates."""

from __future__ import annotations

from collections.abc import Sequence
import math
import struct

MAX_N = 8
MAX_EDGES = 28
MAX_INPUT_LENGTH = 5 + MAX_N + 3 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_N
INF = 1_000_000_000
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _profile(values: Sequence[int] | None) -> list[int] | None:
    if not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    mode, n, base_count, added_count, source = values[:5]
    if not 1 <= mode <= 6 or not 2 <= n <= MAX_N:
        return None
    if not 0 <= base_count or not 1 <= added_count or base_count + added_count > MAX_EDGES:
        return None
    if len(values) != 5 + n + 3 * (base_count + added_count):
        return None
    if mode in (1, 2, 5):
        if not 0 <= source < n:
            return None
    elif source != -1:
        return None

    state = list(values[5 : 5 + n])
    for value in state:
        if mode == 1:
            if not -1 <= value < n:
                return None
        elif mode in (2, 5):
            if not -1 <= value <= INF:
                return None
        elif mode == 3:
            if not -1 <= value <= 1_000_000:
                return None
        elif not -1 <= value < n:
            return None

    neighbors: list[list[int]] = [[] for _ in range(n)]
    edge_weights: list[list[int]] = [[] for _ in range(n)]
    used: set[tuple[int, int]] = set()
    affected: set[int] = set()
    start = 5 + n
    edge_count = base_count + added_count
    for edge_index in range(edge_count):
        pos = start + 3 * edge_index
        u, v, weight = values[pos : pos + 3]
        if not (0 <= u < v < n and 1 <= weight <= 9) or (u, v) in used:
            return None
        used.add((u, v))
        neighbors[u].append(v)
        edge_weights[u].append(weight)
        neighbors[v].append(u)
        edge_weights[v].append(weight)
        if edge_index >= base_count:
            affected.update((u, v))
    if mode == 3 and any(not neighbors[v] for v in range(n)):
        return None

    prop = state
    if mode == 1:
        if prop[source] == -1:
            prop[source] = 0
        queue, seen = [], set()
        for vertex in range(n):
            if vertex not in affected:
                continue
            old = prop[vertex]
            candidate = min(
                (prop[u] + 1 for u in neighbors[vertex] if prop[u] != -1),
                default=INF,
            )
            if candidate != INF and (candidate < old or old == -1):
                prop[vertex] = candidate
                for u in neighbors[vertex]:
                    updated = candidate + 1
                    if prop[u] == -1 or updated < prop[u]:
                        prop[u] = updated
                        _queue_add(u, queue, seen)
        _drain_bfs(prop, neighbors, queue)
    elif mode == 2:
        for vertex in range(n):
            if prop[vertex] == -1:
                prop[vertex] = 0 if vertex == source else INF
        queue, seen = [], set()
        for vertex in range(n):
            if vertex not in affected:
                continue
            candidate = min(
                (prop[u] + edge_weights[vertex][j] for j, u in enumerate(neighbors[vertex])),
                default=INF,
            )
            if candidate < prop[vertex] and candidate != INF:
                prop[vertex] = candidate
                for u in neighbors[vertex]:
                    _queue_add(u, queue, seen)
        _drain_min_weighted(prop, neighbors, edge_weights, queue)
    elif mode == 3:
        return _pagerank(values, prop, neighbors, affected)
    elif mode == 4:
        for vertex in range(n):
            if prop[vertex] == -1:
                prop[vertex] = vertex
        queue, seen = [], set()
        for vertex in range(n):
            if vertex not in affected:
                continue
            old = prop[vertex]
            candidate = min([old, *(prop[u] for u in neighbors[vertex])])
            if candidate < old or old == vertex:
                prop[vertex] = candidate
                for u in neighbors[vertex]:
                    _queue_add(u, queue, seen)
        _drain_label(prop, neighbors, queue, minimum=True)
    elif mode == 5:
        for vertex in range(n):
            if prop[vertex] == -1:
                prop[vertex] = INF if vertex == source else 0
        queue, seen = [], set()
        for vertex in range(n):
            if vertex not in affected:
                continue
            candidate = max(
                (min(prop[u], edge_weights[vertex][j]) for j, u in enumerate(neighbors[vertex])),
                default=0,
            )
            if candidate > prop[vertex]:
                prop[vertex] = candidate
                for u in neighbors[vertex]:
                    _queue_add(u, queue, seen)
        _drain_widest(prop, neighbors, edge_weights, queue)
    else:
        for vertex in range(n):
            if prop[vertex] == -1:
                prop[vertex] = vertex
        queue, seen = [], set()
        for vertex in range(n):
            if vertex not in affected:
                continue
            old = prop[vertex]
            candidate = max([old, *(prop[u] for u in neighbors[vertex])])
            if candidate > old or old == vertex:
                prop[vertex] = candidate
                for u in neighbors[vertex]:
                    _queue_add(u, queue, seen)
        _drain_label(prop, neighbors, queue, minimum=False)
    return prop


def _queue_add(vertex: int, queue: list[int], seen: set[int]) -> None:
    if vertex not in seen:
        seen.add(vertex)
        queue.append(vertex)


def _drain_bfs(prop: list[int], neighbors: list[list[int]], queue: list[int]) -> None:
    rounds = 0
    while queue:
        rounds += 1
        if rounds > 256:
            raise ValueError("bounded update exceeds queue-round limit")
        current, queue = queue, []
        seen: set[int] = set()
        for vertex in current:
            for u in neighbors[vertex]:
                candidate = prop[vertex] + 1
                if prop[u] == -1 or candidate < prop[u]:
                    prop[u] = candidate
                    _queue_add(u, queue, seen)


def _drain_min_weighted(
    prop: list[int], neighbors: list[list[int]], edge_weights: list[list[int]], queue: list[int]
) -> None:
    rounds = 0
    while queue:
        rounds += 1
        if rounds > 256:
            raise ValueError("bounded update exceeds queue-round limit")
        current, queue = queue, []
        seen: set[int] = set()
        for vertex in current:
            candidate = min(
                (prop[u] + edge_weights[vertex][j] for j, u in enumerate(neighbors[vertex])),
                default=INF,
            )
            if candidate < prop[vertex] and candidate != INF:
                prop[vertex] = candidate
                for u in neighbors[vertex]:
                    _queue_add(u, queue, seen)


def _drain_label(
    prop: list[int], neighbors: list[list[int]], queue: list[int], *, minimum: bool
) -> None:
    rounds = 0
    while queue:
        rounds += 1
        if rounds > 256:
            raise ValueError("bounded update exceeds queue-round limit")
        current, queue = queue, []
        seen: set[int] = set()
        for vertex in current:
            values = [prop[vertex], *(prop[u] for u in neighbors[vertex])]
            candidate = min(values) if minimum else max(values)
            changed = candidate < prop[vertex] if minimum else candidate > prop[vertex]
            if changed:
                prop[vertex] = candidate
                for u in neighbors[vertex]:
                    _queue_add(u, queue, seen)


def _drain_widest(
    prop: list[int], neighbors: list[list[int]], edge_weights: list[list[int]], queue: list[int]
) -> None:
    rounds = 0
    while queue:
        rounds += 1
        if rounds > 256:
            raise ValueError("bounded update exceeds queue-round limit")
        current, queue = queue, []
        seen: set[int] = set()
        for vertex in current:
            candidate = max(
                (min(prop[u], edge_weights[vertex][j]) for j, u in enumerate(neighbors[vertex])),
                default=0,
            )
            if candidate > prop[vertex]:
                prop[vertex] = candidate
                for u in neighbors[vertex]:
                    _queue_add(u, queue, seen)


def _pagerank(values: Sequence[int], prop: list[int], neighbors: list[list[int]], affected: set[int]) -> list[int]:
    n = len(prop)
    damping = _f32(0.85)
    base = _f32(_f32(_f32(1.0) - damping) / _f32(n))
    rank = [_f32(_f32(1.0) / _f32(n)) if value == -1 else _f32(_f32(value) / _f32(1_000_000)) for value in prop]
    contribution = [_f32(rank[v] / _f32(len(neighbors[v]))) for v in range(n)]
    queue: list[int] = []
    seen: set[int] = set()
    for vertex in range(n):
        if vertex not in affected:
            continue
        incoming = _f32(0.0)
        for u in neighbors[vertex]:
            incoming = _f32(incoming + contribution[u])
        old = rank[vertex]
        rank[vertex] = _f32(base + _f32(damping * incoming))
        if abs(_f32(rank[vertex] - old)) > _f32(1e-7):
            for u in neighbors[vertex]:
                _queue_add(u, queue, seen)
    rounds = 0
    while queue:
        rounds += 1
        if rounds > 256:
            raise ValueError("bounded PageRank update exceeds queue-round limit")
        contribution = [_f32(rank[v] / _f32(len(neighbors[v]))) for v in range(n)]
        current, queue = queue, []
        seen = set()
        for vertex in current:
            incoming = _f32(0.0)
            for u in neighbors[vertex]:
                incoming = _f32(incoming + contribution[u])
            old = rank[vertex]
            rank[vertex] = _f32(base + _f32(damping * incoming))
            if abs(_f32(rank[vertex] - old)) > _f32(1e-7):
                for u in neighbors[vertex]:
                    _queue_add(u, queue, seen)
    return [int(math.floor(_f32(_f32(value * _f32(1_000_000)) + _f32(0.5)))) for value in rank]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the final state as little-endian i64 values or an ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    try:
        result = _profile(values)
    except (IndexError, OverflowError, ValueError):
        return INVALID_RESULT, b""
    if result is None:
        return INVALID_RESULT, b""
    encoded = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    return expected_output(values)

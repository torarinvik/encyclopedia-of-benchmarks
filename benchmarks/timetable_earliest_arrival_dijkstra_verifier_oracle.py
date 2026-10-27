"""Independent exhaustive-path verifier for DOI 371 timetable routes."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_ARCS = 12
MAX_TRIPS = 4
MAX_INPUT_LENGTH = 138


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= (1 << 63) for item in values):
        return None
    n, edge_count, source, target, start = values[:5]
    if not 2 <= n <= MAX_N or not 0 <= edge_count <= MAX_ARCS:
        return None
    if not 0 <= source < n or not 0 <= target < n or not 0 <= start <= 1000:
        return None
    p = 5
    schedules: dict[tuple[int, int], tuple[tuple[int, int], ...]] = {}
    for _ in range(edge_count):
        if p + 3 > len(values):
            return None
        u, v, count = values[p], values[p + 1], values[p + 2]
        p += 3
        if (not 0 <= u < n or not 0 <= v < n or u == v or not 1 <= count <= MAX_TRIPS
                or (u, v) in schedules or p + 2 * count > len(values)):
            return None
        times = []
        for _ in range(count):
            dep, arr = values[p], values[p + 1]
            p += 2
            if not 0 <= dep <= 1000 or not dep < arr <= 2000:
                return None
            if times and (dep <= times[-1][0] or arr < times[-1][1]):
                return None
            times.append((dep, arr))
        schedules[(u, v)] = tuple(times)
    if p != len(values):
        return None
    return n, source, target, start, schedules


def _earliest_after(events: tuple[tuple[int, int], ...], ready: int) -> int | None:
    eligible = [arrival for departure, arrival in events if departure >= ready]
    return min(eligible) if eligible else None


def _check(n: int, source: int, target: int, start: int,
           schedules: dict[tuple[int, int], tuple[tuple[int, int], ...]]) -> list[int]:
    # Enumerate every simple station path, rather than using the package's Dijkstra recurrence.
    best: list[int | None] = [None] * n
    best[source] = start

    def visit(u: int, time: int, seen: frozenset[int]) -> None:
        for (tail, head), events in schedules.items():
            if tail != u or head in seen:
                continue
            next_time = _earliest_after(events, time)
            if next_time is None:
                continue
            if best[head] is None or next_time < best[head]:
                best[head] = next_time
            visit(head, next_time, seen | {head})

    visit(source, start, frozenset({source}))
    if best[target] is None:
        return [0, -1, 0]
    # Reconstruct the specified predecessor tie rule from independently enumerated
    # optimal station arrival times: use the smallest predecessor vertex ID.
    parent = [-1] * n
    for (u, v), events in schedules.items():
        if best[u] is None or best[v] is None:
            continue
        if _earliest_after(events, best[u]) == best[v] and (parent[v] < 0 or u < parent[v]):
            parent[v] = u
    reverse = [target]
    current = target
    while current != source and len(reverse) < n:
        current = parent[current]
        if current < 0:
            return [0, -1, 0]
        reverse.append(current)
    if reverse[-1] != source:
        return [0, -1, 0]
    path = list(reversed(reverse))
    return [1, best[target], len(path), *path]


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
    n, source, target, start, schedules = decoded
    words = _check(n, source, target, start, schedules)
    encoded = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded

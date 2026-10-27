"""Primary bounded oracle for DOI 371's timetable earliest-arrival profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_ARCS = 12
MAX_TRIPS = 4
MAX_INPUT_LENGTH = 138
MAX_OUTPUT_BYTES = 88
MAX_WORKSPACE_BYTES = 4096
INF = 1 << 60


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, arc_count, source, target, start_time = values[:5]
    if (not 2 <= n <= MAX_N or not 0 <= arc_count <= MAX_ARCS
            or not 0 <= source < n or not 0 <= target < n or not 0 <= start_time <= 1000):
        return None
    cursor = 5
    arcs: list[tuple[int, int, tuple[tuple[int, int], ...]]] = []
    endpoints: set[tuple[int, int]] = set()
    for _ in range(arc_count):
        if cursor + 3 > len(values):
            return None
        u, v, trip_count = values[cursor:cursor + 3]
        cursor += 3
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 1 <= trip_count <= MAX_TRIPS
                or cursor + 2 * trip_count > len(values) or (u, v) in endpoints):
            return None
        endpoints.add((u, v))
        trips: list[tuple[int, int]] = []
        for _ in range(trip_count):
            departure, arrival = values[cursor:cursor + 2]
            cursor += 2
            if (not 0 <= departure <= 1000 or not departure < arrival <= 2000
                    or trips and (departure <= trips[-1][0] or arrival < trips[-1][1])):
                return None
            trips.append((departure, arrival))
        arcs.append((u, v, tuple(trips)))
    if cursor != len(values):
        return None
    return n, source, target, start_time, arcs


def _next_arrival(trips: tuple[tuple[int, int], ...], ready_time: int) -> int | None:
    for departure, arrival in trips:
        if departure >= ready_time:
            return arrival
    return None


def _run(n: int, source: int, target: int, start_time: int,
         arcs: list[tuple[int, int, tuple[tuple[int, int], ...]]]) -> list[int]:
    arrival = [INF] * n
    parent = [-1] * n
    settled = [False] * n
    outgoing: list[list[tuple[int, tuple[tuple[int, int], ...]]]] = [[] for _ in range(n)]
    for u, v, trips in arcs:
        outgoing[u].append((v, trips))
    arrival[source] = start_time
    for _ in range(n):
        candidates = [v for v in range(n) if not settled[v] and arrival[v] < INF]
        if not candidates:
            break
        u = min(candidates, key=lambda vertex: (arrival[vertex], vertex))
        settled[u] = True
        for v, trips in outgoing[u]:
            if settled[v]:
                continue
            offered = _next_arrival(trips, arrival[u])
            if offered is not None and (offered < arrival[v]
                                        or offered == arrival[v]
                                        and (parent[v] < 0 or u < parent[v])):
                arrival[v] = offered
                parent[v] = u
    if arrival[target] == INF:
        return [0, -1, 0]
    reverse_path = [target]
    current = target
    while current != source and len(reverse_path) < n:
        current = parent[current]
        if current < 0:
            return [0, -1, 0]
        reverse_path.append(current)
    if reverse_path[-1] != source:
        return [0, -1, 0]
    path = list(reversed(reverse_path))
    return [1, arrival[target], len(path), *path]


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
    n, source, target, start_time, arcs = parsed
    words = _run(n, source, target, start_time, arcs)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

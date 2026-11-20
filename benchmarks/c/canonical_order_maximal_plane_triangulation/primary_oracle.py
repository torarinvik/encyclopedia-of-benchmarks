"""Primary bounded reference for canonical-order reverse shelling."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 7 * MAX_N - 8
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)
WORKSPACE_BYTES = 4096


def _decode(values: Sequence[int]):
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, u, v, w = values[:4]
    if not 3 <= n <= MAX_N or len({u, v, w}) != 3 or any(not 0 <= root < n for root in (u, v, w)):
        return None
    rotations: list[list[int]] = []
    offset = 4
    for vertex in range(n):
        if offset >= len(values):
            return None
        degree = values[offset]
        offset += 1
        if not 2 <= degree <= n - 1 or offset + degree > len(values):
            return None
        around = list(values[offset:offset + degree])
        offset += degree
        if (len(set(around)) != degree or any(not 0 <= neighbor < n or neighbor == vertex
                                                for neighbor in around)):
            return None
        rotations.append(around)
    if offset != len(values):
        return None

    adjacent = [[False] * n for _ in range(n)]
    degree_sum = 0
    for vertex, around in enumerate(rotations):
        degree_sum += len(around)
        for neighbor in around:
            adjacent[vertex][neighbor] = True
    if degree_sum != 6 * n - 12:
        return None
    if any(adjacent[a][b] != adjacent[b][a] for a in range(n) for b in range(n)):
        return None
    if sum(adjacent[a][b] for a in range(n) for b in range(a + 1, n)) != 3 * n - 6:
        return None

    reached = {0}
    stack = [0]
    while stack:
        vertex = stack.pop()
        for neighbor in range(n):
            if adjacent[vertex][neighbor] and neighbor not in reached:
                reached.add(neighbor)
                stack.append(neighbor)
    if len(reached) != n:
        return None

    def next_clockwise(active: list[bool], source: int, target: int) -> int | None:
        around = [neighbor for neighbor in rotations[target] if active[neighbor]]
        if len(around) < 2 or source not in around:
            return None
        return around[(around.index(source) + 1) % len(around)]

    def face_cycle(active: list[bool], first: int, second: int) -> list[int] | None:
        cycle: list[int] = []
        seen: set[tuple[int, int]] = set()
        source, target = first, second
        for _ in range(2 * (3 * n - 6) + 1):
            dart = (source, target)
            if dart in seen:
                return cycle if dart == (first, second) else None
            if not active[source] or not active[target] or not adjacent[source][target]:
                return None
            seen.add(dart)
            cycle.append(source)
            following = next_clockwise(active, source, target)
            if following is None:
                return None
            source, target = target, following
            if (source, target) == (first, second):
                return cycle
        return None

    all_active = [True] * n
    visited_darts: set[tuple[int, int]] = set()
    face_count = 0
    for source in range(n):
        for target in range(n):
            if adjacent[source][target] and (source, target) not in visited_darts:
                face = face_cycle(all_active, source, target)
                if face is None or len(face) != 3:
                    return None
                face_count += 1
                visited_darts.update((face[index], face[(index + 1) % len(face)])
                                     for index in range(len(face)))
    if face_count != 2 * n - 4 or len(visited_darts) != 6 * n - 12:
        return None
    if face_cycle(all_active, u, v) != [u, v, w]:
        return None
    return n, u, v, w, rotations, adjacent


def _boundary(rotations: list[list[int]], adjacent: list[list[bool]], active: list[bool],
              u: int, v: int) -> list[int] | None:
    around_count = len(rotations)

    def successor(source: int, target: int) -> int | None:
        around = [neighbor for neighbor in rotations[target] if active[neighbor]]
        if len(around) < 2 or source not in around:
            return None
        return around[(around.index(source) + 1) % len(around)]

    cycle: list[int] = []
    seen: set[tuple[int, int]] = set()
    source, target = u, v
    for _ in range(2 * (3 * around_count - 6) + 1):
        dart = (source, target)
        if dart in seen:
            return None
        if not active[source] or not active[target] or not adjacent[source][target]:
            return None
        seen.add(dart)
        cycle.append(source)
        following = successor(source, target)
        if following is None:
            return None
        source, target = target, following
        if (source, target) == (u, v):
            if len(cycle) < 3:
                return None
            return [u, *reversed(cycle[2:]), v]
    return None


def _eligible(boundary: list[int], adjacent: list[list[bool]]) -> list[int]:
    chords: list[tuple[int, int]] = []
    length = len(boundary)
    for left in range(length):
        for right in range(left + 2, length):
            if left == 0 and right == length - 1:
                continue
            if adjacent[boundary[left]][boundary[right]]:
                chords.append((left, right))
    if not chords:
        return boundary[1:-1]
    minimal = [chord for chord in chords
               if not any(chord != other and chord[0] <= other[0] < other[1] <= chord[1]
                          for other in chords)]
    return [boundary[position] for left, right in minimal
            for position in range(left + 1, right)]


def _shell(values: Sequence[int]):
    parsed = _decode(values)
    if parsed is None:
        return None
    n, u, v, w, rotations, adjacent = parsed
    if n == 3:
        return [u, v, w]
    active = [True] * n
    active[w] = False  # The theorem's reverse construction fixes v_n = w.
    removals = [w]
    current = _boundary(rotations, adjacent, active, u, v)
    if current is None:
        return None
    active_count = n - 1
    while active_count > 3:
        choices = _eligible(current, adjacent)
        if not choices:
            return None
        vertex = min(choices)
        if vertex in (u, v) or not active[vertex]:
            return None
        active[vertex] = False
        removals.append(vertex)
        active_count -= 1
        current = _boundary(rotations, adjacent, active, u, v)
        if current is None:
            return None
    remaining = [vertex for vertex in range(n) if active[vertex]]
    if len(current) != 3 or current[0] != u or current[-1] != v or current[1] not in remaining:
        return None
    if len(set(current)) != 3 or set(current) != set(remaining):
        return None
    order = [u, v, current[1], *reversed(removals)]
    if len(order) != n or len(set(order)) != n or order[-1] != w:
        return None
    return order


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    order = _shell(values)
    if order is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", word) for word in (len(order), *order))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

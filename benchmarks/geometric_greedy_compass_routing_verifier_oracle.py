"""Independent cross-product angle ordering for geometric routing verification."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 84
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 80


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 12 or len(values) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, mode, start, goal = values[:4]
    if not 2 <= n <= MAX_N or mode not in (0, 1) or not (0 <= start < n and 0 <= goal < n):
        return None
    if len(values) != 4 + 2*n + n*n:
        return None
    px, py = list(values[4:4+n]), list(values[4+n:4+2*n])
    if any(not -8 <= x <= 8 for x in px + py) or len(set(zip(px, py))) != n:
        return None
    graph = [list(values[4+2*n+i*n:4+2*n+(i+1)*n]) for i in range(n)]
    for i in range(n):
        if graph[i][i] != 0:
            return None
        for j in range(n):
            if graph[i][j] not in (0, 1) or graph[i][j] != graph[j][i]:
                return None
    return n, mode, start, goal, px, py, graph


def _angle_precedes(a: tuple[int, int], b: tuple[int, int]) -> bool:
    """Compare target-relative angles via acute/obtuse half-planes and slopes."""
    cross_a, dot_a = a
    cross_b, dot_b = b
    if (dot_a >= 0) != (dot_b >= 0):
        return dot_a >= 0
    if dot_a >= 0:
        if dot_a == 0 or dot_b == 0:
            return dot_b == 0 and dot_a > 0
        return cross_a * dot_b < cross_b * dot_a
    return cross_a * (-dot_b) > cross_b * (-dot_a)


def _angle_equal(a: tuple[int, int], b: tuple[int, int]) -> bool:
    cross_a, dot_a = a
    cross_b, dot_b = b
    if (dot_a >= 0) != (dot_b >= 0):
        return False
    if dot_a == 0 or dot_b == 0:
        return dot_a == 0 and dot_b == 0
    return cross_a * abs(dot_b) == cross_b * abs(dot_a)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, mode, start, goal, px, py, graph = decoded
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""

    route = [start]
    seen = {start}
    node = start
    while node != goal and len(route) < n:
        candidates = [v for v in range(n) if graph[node][v] == 1]
        if not candidates:
            break
        if mode == 0:
            next_node = min(candidates, key=lambda v: ((px[v]-px[goal])**2 + (py[v]-py[goal])**2, v))
        else:
            tx, ty = px[goal] - px[node], py[goal] - py[node]
            best = candidates[0]
            dx, dy = px[best] - px[node], py[best] - py[node]
            best_vec = (abs(tx*dy - ty*dx), tx*dx + ty*dy)
            for candidate in candidates[1:]:
                dx, dy = px[candidate] - px[node], py[candidate] - py[node]
                vec = (abs(tx*dy - ty*dx), tx*dx + ty*dy)
                if _angle_precedes(vec, best_vec) or _angle_equal(vec, best_vec) and candidate < best:
                    best, best_vec = candidate, vec
            next_node = best
        if next_node in seen:
            break
        route.append(next_node)
        seen.add(next_node)
        node = next_node
    delivered = node == goal
    record = [int(delivered), len(route)-1, *route, *([-1] * (MAX_N-len(route)))]
    packed = b"".join(struct.pack("<q", item) for item in record)
    return len(packed), packed

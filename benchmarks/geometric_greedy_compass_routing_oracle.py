"""Exact bounded Greedy/Compass geometric routing profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 84
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 80


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 12 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, mode, source, target = values[:4]
    if not 2 <= n <= MAX_N or mode not in (0, 1) or not 0 <= source < n or not 0 <= target < n:
        return None
    if len(values) != 4 + 2 * n + n * n:
        return None
    xs = list(values[4:4+n])
    ys = list(values[4+n:4+2*n])
    if any(not -8 <= x <= 8 for x in xs) or any(not -8 <= y <= 8 for y in ys):
        return None
    if len(set(zip(xs, ys))) != n:
        return None
    raw = values[4 + 2*n:]
    adjacency = [list(raw[i*n:(i+1)*n]) for i in range(n)]
    if any(value not in (0, 1) for row in adjacency for value in row):
        return None
    if any(adjacency[i][i] != 0 for i in range(n)):
        return None
    if any(adjacency[i][j] != adjacency[j][i] for i in range(n) for j in range(n)):
        return None
    return n, mode, source, target, xs, ys, adjacency


def _angle_better(dot_a: int, len_a: int, dot_b: int, len_b: int) -> bool:
    """Whether a has larger cosine (and thus smaller angle) than b."""
    if (dot_a >= 0) != (dot_b >= 0):
        return dot_a >= 0
    left = dot_a * dot_a * len_b
    right = dot_b * dot_b * len_a
    return left > right if dot_a >= 0 else left < right


def _angle_equal(dot_a: int, len_a: int, dot_b: int, len_b: int) -> bool:
    if (dot_a >= 0) != (dot_b >= 0):
        return False
    return dot_a * dot_a * len_b == dot_b * dot_b * len_a


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, mode, source, target, xs, ys, adjacency = parsed
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""

    path = [source]
    visited = {source}
    current = source
    delivered = current == target
    while not delivered and len(path) < n:
        neighbors = [v for v in range(n) if adjacency[current][v]]
        if not neighbors:
            break
        if mode == 0:
            nxt = min(neighbors, key=lambda v: ((xs[v]-xs[target])**2 + (ys[v]-ys[target])**2, v))
        else:
            tx, ty = xs[target] - xs[current], ys[target] - ys[current]
            best = neighbors[0]
            vx, vy = xs[best] - xs[current], ys[best] - ys[current]
            best_dot, best_len = vx*tx + vy*ty, vx*vx + vy*vy
            for v in neighbors[1:]:
                vx, vy = xs[v] - xs[current], ys[v] - ys[current]
                dot, length_sq = vx*tx + vy*ty, vx*vx + vy*vy
                if (_angle_better(dot, length_sq, best_dot, best_len)
                        or _angle_equal(dot, length_sq, best_dot, best_len) and v < best):
                    best, best_dot, best_len = v, dot, length_sq
            nxt = best
        if nxt in visited:
            break
        path.append(nxt)
        visited.add(nxt)
        current = nxt
        delivered = current == target

    record = [int(delivered), len(path)-1, *path, *([-1] * (MAX_N-len(path)))]
    output = b"".join(struct.pack("<q", value) for value in record)
    return len(output), output

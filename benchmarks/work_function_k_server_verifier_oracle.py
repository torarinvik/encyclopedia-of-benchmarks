"""Independent verifier oracle using a matching-cost subset DP."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from itertools import combinations

MAX_INPUT = 50


def _minimum_matching(left: tuple[int, ...], right: tuple[int, ...], metric: list[list[int]]) -> int:
    # Assign each left server to a distinct right position by a bitmask DP.
    costs = [0] + [1 << 60] * ((1 << len(left)) - 1)
    for mask in range(1 << len(left)):
        row = mask.bit_count()
        if row == len(left):
            continue
        for column in range(len(right)):
            bit = 1 << column
            if not mask & bit:
                target = mask | bit
                candidate = costs[mask] + metric[left[row]][right[column]]
                if candidate < costs[target]:
                    costs[target] = candidate
    return costs[-1]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    p, k, count = values[:3]
    if not 2 <= p <= 6 or not 1 <= k <= 3 or k > p or not 0 <= count <= 8:
        return -1, b""
    initial_pos = 3 + p*p
    request_pos = initial_pos + k
    if len(values) != request_pos + count:
        return -1, b""
    matrix = [list(values[3+i*p:3+(i+1)*p]) for i in range(p)]
    if any(x < 0 or x > 1000 for row in matrix for x in row):
        return -1, b""
    for a in range(p):
        for b in range(p):
            if (matrix[a][b] != matrix[b][a] or (a == b) != (matrix[a][b] == 0)
                    or any(matrix[a][b] > matrix[a][c] + matrix[c][b] for c in range(p))):
                return -1, b""
    current = tuple(sorted(values[initial_pos:request_pos]))
    requests = values[request_pos:]
    if len(set(current)) != k or any(not 0 <= x < p for x in current + tuple(requests)):
        return -1, b""

    states = tuple(combinations(range(p), k))
    move_cost = {(a, b): _minimum_matching(a, b, matrix) for a in states for b in states}
    work = {state: _minimum_matching(current, state, matrix) for state in states}
    frame = [count, k]
    for request in requests:
        updated = {}
        for target in states:
            best = None
            for source in states:
                if request in source:
                    candidate = work[source] + move_cost[source, target]
                    if best is None or candidate < best:
                        best = candidate
            updated[target] = best
        if request in current:
            following = current
        else:
            best_key = None
            following = current
            for slot, old_point in enumerate(current):
                candidate = tuple(sorted(current[:slot] + (request,) + current[slot+1:]))
                key = (work[candidate] + matrix[old_point][request], slot)
                if best_key is None or key < best_key:
                    best_key, following = key, candidate
        frame.extend(following)
        current, work = following, updated
    payload = b"".join(struct.pack("<q", x) for x in frame)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

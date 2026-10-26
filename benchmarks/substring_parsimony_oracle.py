"""Tree dynamic-programming oracle for a bounded substring-parsimony profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_STATES = 4
MAX_INPUT_LENGTH = 26
MAX_OUTPUT_BYTES = 40_976
MAX_SCORE = 36
INF = 1 << 30


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 10 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    q, threshold = values[0], values[1]
    if not 1 <= q <= MAX_STATES or not 0 <= threshold <= MAX_SCORE:
        return None
    if len(values) != 9 + q * q:
        return None
    c00, c01, c10, c11 = values[2:6]
    children = ((c00, c01), (c10, c11))
    if any(child < 1 or child > 4 for pair in children for child in pair):
        return None
    if c00 == c01 or c10 == c11 or 1 not in children[0]:
        return None
    root_leaf = c01 if c00 == 1 else c00
    if root_leaf < 2 or root_leaf > 4:
        return None
    leaves = {2, 3, 4}
    if set(children[1]) != leaves - {root_leaf}:
        return None
    if set(children[0]) != {1, root_leaf}:
        return None
    masks = tuple(values[6:9])
    universe = (1 << q) - 1
    if any(mask <= 0 or mask > universe for mask in masks):
        return None
    raw_distance = values[9:]
    distance = tuple(tuple(raw_distance[i * q:(i + 1) * q]) for i in range(q))
    for i in range(q):
        for j in range(q):
            value = distance[i][j]
            if type(value) is not int or not 0 <= value <= 9:
                return None
            if (i == j and value != 0) or (i != j and value == 0):
                return None
            if value != distance[j][i]:
                return None
    for i in range(q):
        for j in range(q):
            for k in range(q):
                if distance[i][k] > distance[i][j] + distance[j][k]:
                    return None
    return q, threshold, children, masks, distance


def _payload(values: Sequence[int] | None) -> bytes | None:
    parsed = _parse(values)
    if parsed is None:
        return None
    q, threshold, children, masks, distance = parsed
    children_by_node = {0: children[0], 1: children[1]}
    leaf_mask = {2: masks[0], 3: masks[1], 4: masks[2]}

    # The source recurrence: W_u[s] is the best score below u with u fixed to s.
    table = [[INF] * q for _ in range(5)]
    for node in (2, 3, 4):
        for state in range(q):
            if leaf_mask[node] & (1 << state):
                table[node][state] = 0
    for node in (1, 0):
        for state in range(q):
            table[node][state] = sum(
                min(table[child][other] + distance[state][other] for other in range(q))
                for child in children_by_node[node]
            )
    optimum = min(table[0])
    if optimum >= INF:
        return None

    # Trace only recurrence-minimizing child choices. This emits every optimal
    # labeling, in canonical node-index order, without enumerating nonoptimal ones.
    def trace(node: int, state: int, partial: dict[int, int]) -> list[dict[int, int]]:
        partial = dict(partial)
        partial[node] = state
        if node >= 2:
            return [partial]
        results = [partial]
        for child in children_by_node[node]:
            best_edge = min(table[child][other] + distance[state][other]
                            for other in range(q))
            child_maps: list[dict[int, int]] = []
            for other in range(q):
                if table[child][other] + distance[state][other] == best_edge:
                    child_maps.extend(trace(child, other, {}))
            results = [{**left, **right} for left in results for right in child_maps]
        return results

    rows: set[tuple[int, ...]] = set()
    if optimum <= threshold:
        for root_state in range(q):
            if table[0][root_state] == optimum:
                rows.update(tuple(assignment[node] for node in range(5))
                            for assignment in trace(0, root_state, {}))
    ordered = sorted(rows)
    words = [optimum, len(ordered)]
    for row in ordered:
        words.extend(row)
    return struct.pack("<" + "q" * len(words), *words)


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
    payload = _payload(values)
    if payload is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

"""Brute-force assignment verifier for the bounded substring-parsimony profile."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 26
MAX_OUTPUT_BYTES = 40_976


def _problem(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 10
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    q, threshold = values[:2]
    if not 1 <= q <= 4 or not 0 <= threshold <= 36 or len(values) != 9 + q * q:
        return None
    children = ((values[2], values[3]), (values[4], values[5]))
    if (any(v not in (1, 2, 3, 4) for pair in children for v in pair)
            or children[0][0] == children[0][1] or children[1][0] == children[1][1]
            or 1 not in children[0]):
        return None
    other_root_child = children[0][1] if children[0][0] == 1 else children[0][0]
    if not 2 <= other_root_child <= 4 or set(children[1]) != ({2, 3, 4} - {other_root_child}):
        return None
    masks = values[6:9]
    if any(mask <= 0 or mask >= (1 << q) for mask in masks):
        return None
    d = [values[9 + row * q:9 + (row + 1) * q] for row in range(q)]
    for a in range(q):
        for b in range(q):
            if not 0 <= d[a][b] <= 9 or (a == b) != (d[a][b] == 0):
                return None
            if d[a][b] != d[b][a]:
                return None
            for c in range(q):
                if d[a][c] > d[a][b] + d[b][c]:
                    return None
    return q, threshold, children, masks, d


def _brute_result(values: Sequence[int] | None) -> bytes | None:
    problem = _problem(values)
    if problem is None:
        return None
    q, threshold, children, masks, distance = problem
    edges = [(0, child) for child in children[0]] + [(1, child) for child in children[1]]
    best = None
    winners: list[tuple[int, ...]] = []
    for assignment in itertools.product(range(q), repeat=5):
        if any(not (masks[leaf - 2] & (1 << assignment[leaf])) for leaf in (2, 3, 4)):
            continue
        score = sum(distance[assignment[parent]][assignment[child]]
                    for parent, child in edges)
        row = tuple(assignment)
        if best is None or score < best:
            best = score
            winners = [row]
        elif score == best:
            winners.append(row)
    if best is None:
        return None
    if best > threshold:
        winners = []
    words = [best, len(winners)]
    for row in sorted(winners):
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
    payload = _brute_result(values)
    if payload is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

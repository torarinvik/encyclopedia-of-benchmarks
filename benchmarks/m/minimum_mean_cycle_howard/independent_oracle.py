"""Simple-cycle enumeration oracle for minimum mean cycle."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
import struct

MAX_VERTICES = 8
MAX_EDGES = 16
MAX_PARSEABLE_INPUT_LENGTH = 51
OUTPUT_BYTES = 16


def _validated_graph(values: Sequence[int] | None, input_is_null: bool,
                     input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 1 <= m <= min(MAX_EDGES, n * n):
        return None
    if len(values) != 2 + 3 * m:
        return None
    edges = []
    pairs = set()
    outgoing = [[] for _ in range(n)]
    forward = [[] for _ in range(n)]
    reverse = [[] for _ in range(n)]
    for i in range(m):
        u, v, weight = values[2 + 3 * i:5 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or not -1000 <= weight <= 1000:
            return None
        if (u, v) in pairs:
            return None
        pairs.add((u, v))
        edges.append((u, v, weight))
        outgoing[u].append((v, weight))
        forward[u].append(v)
        reverse[v].append(u)
    for adjacency in (forward, reverse):
        reached = {0}
        pending = [0]
        while pending:
            vertex = pending.pop()
            for neighbor in adjacency[vertex]:
                if neighbor not in reached:
                    reached.add(neighbor)
                    pending.append(neighbor)
        if len(reached) != n:
            return None
    return n, outgoing


def _enumerate_minimum_mean(n: int, outgoing) -> Fraction:
    best: Fraction | None = None

    def extend(start: int, vertex: int, seen: set[int], total: int, length: int) -> None:
        nonlocal best
        for neighbor, weight in outgoing[vertex]:
            if neighbor == start:
                candidate = Fraction(total + weight, length + 1)
                if best is None or candidate < best:
                    best = candidate
            elif neighbor > start and neighbor not in seen:
                extend(start, neighbor, seen | {neighbor}, total + weight, length + 1)

    for start in range(n):
        extend(start, start, {start}, 0, 0)
    if best is None:
        raise ValueError("strongly connected input must contain a directed cycle")
    return best


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _validated_graph(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or (capacity is not None and capacity < OUTPUT_BYTES):
        return -2, b""
    numerator, denominator = _enumerate_minimum_mean(*parsed).as_integer_ratio()
    return OUTPUT_BYTES, struct.pack("<qq", numerator, denominator)

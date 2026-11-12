"""Direct simple-cycle enumeration oracle for minimum mean cycle certificates."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd
import struct

MAX_VERTICES = 8
MAX_EDGES = 16
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
OUTPUT_BYTES = 16


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, tuple[tuple[int, int, int], ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    for value in values:
        if type(value) is not int or value < -(1 << 63) or value >= (1 << 63):
            return None
    n, m = values[0], values[1]
    if n < 1 or n > MAX_VERTICES or m < 1 or m > min(MAX_EDGES, n * n) or len(values) != 2 + 3 * m:
        return None
    edges: list[tuple[int, int, int]] = []
    seen: set[tuple[int, int]] = set()
    forward = [[] for _ in range(n)]
    reverse = [[] for _ in range(n)]
    for index in range(m):
        u, v, weight = values[2 + 3 * index : 5 + 3 * index]
        if u < 0 or u >= n or v < 0 or v >= n or weight < -1000 or weight > 1000 or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v, weight))
        forward[u].append((v, weight))
        reverse[v].append(u)
    for adjacency in (forward, reverse):
        reached = {0}
        pending = [0]
        while pending:
            u = pending.pop()
            neighbors = (edge[0] for edge in adjacency[u]) if adjacency is forward else iter(adjacency[u])
            for v in neighbors:
                if v not in reached:
                    reached.add(v)
                    pending.append(v)
        if len(reached) != n:
            return None
    return n, tuple(edges)


def _enumerate_cycles(n: int, edges: Sequence[tuple[int, int, int]]) -> tuple[int, int]:
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for u, v, weight in edges:
        adjacency[u].append((v, weight))

    best: tuple[int, int] | None = None

    def record(numerator: int, denominator: int) -> None:
        nonlocal best
        if best is None or numerator * best[1] < best[0] * denominator:
            best = (numerator, denominator)

    def visit(start: int, current: int, used: int, total: int, length: int) -> None:
        for following, weight in adjacency[current]:
            if following == start:
                record(total + weight, length + 1)
            elif following > start and not (used & (1 << following)):
                visit(start, following, used | (1 << following), total + weight, length + 1)

    for start in range(n):
        visit(start, start, 1 << start, 0, 0)
    if best is None:
        raise ValueError("strongly connected input must contain a directed cycle")
    divisor = gcd(abs(best[0]), best[1])
    return best[0] // divisor, best[1] // divisor


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or capacity is not None and capacity < OUTPUT_BYTES:
        return -2, b""
    numerator, denominator = _enumerate_cycles(*parsed)
    return OUTPUT_BYTES, struct.pack("<qq", numerator, denominator)

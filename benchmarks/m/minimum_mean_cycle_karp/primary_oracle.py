"""Karp exact-length dynamic program for a bounded strongly connected digraph."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd
import struct

MAX_VERTICES = 8
MAX_EDGES = 16
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
OUTPUT_BYTES = 16
MAX_OUTPUT_BYTES = OUTPUT_BYTES
WORKSPACE_BYTES = 2048
MAX_WORKSPACE_BYTES = WORKSPACE_BYTES


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, tuple[tuple[int, int, int], ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, edge_count = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 1 <= edge_count <= min(MAX_EDGES, n * n):
        return None
    if len(values) != 2 + 3 * edge_count:
        return None
    edges: list[tuple[int, int, int]] = []
    pairs: set[tuple[int, int]] = set()
    for i in range(edge_count):
        u, v, weight = values[2 + 3 * i : 5 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or not -1000 <= weight <= 1000:
            return None
        if (u, v) in pairs:
            return None
        pairs.add((u, v))
        edges.append((u, v, weight))

    forward = [[] for _ in range(n)]
    reverse = [[] for _ in range(n)]
    for u, v, _ in edges:
        forward[u].append(v)
        reverse[v].append(u)
    for adjacency in (forward, reverse):
        reached = {0}
        stack = [0]
        while stack:
            u = stack.pop()
            for v in adjacency[u]:
                if v not in reached:
                    reached.add(v)
                    stack.append(v)
        if len(reached) != n:
            return None
    return n, tuple(edges)


def _less(left: tuple[int, int], right: tuple[int, int]) -> bool:
    return left[0] * right[1] < right[0] * left[1]


def _reduced(numerator: int, denominator: int) -> tuple[int, int]:
    divisor = gcd(abs(numerator), denominator)
    return numerator // divisor, denominator // divisor


def _karp_mean(n: int, edges: Sequence[tuple[int, int, int]]) -> tuple[int, int]:
    reachable = [[False] * n for _ in range(n + 1)]
    cost = [[0] * n for _ in range(n + 1)]
    reachable[0][0] = True
    for length in range(1, n + 1):
        for u, v, weight in edges:
            if not reachable[length - 1][u]:
                continue
            candidate = cost[length - 1][u] + weight
            if not reachable[length][v] or candidate < cost[length][v]:
                reachable[length][v] = True
                cost[length][v] = candidate

    answer: tuple[int, int] | None = None
    for v in range(n):
        if not reachable[n][v]:
            continue
        local_maximum: tuple[int, int] | None = None
        for length in range(n):
            if not reachable[length][v]:
                continue
            ratio = (cost[n][v] - cost[length][v], n - length)
            if local_maximum is None or _less(local_maximum, ratio):
                local_maximum = ratio
        if local_maximum is not None and (answer is None or _less(local_maximum, answer)):
            answer = local_maximum
    if answer is None:
        raise ValueError("strongly connected input must contain a directed cycle")
    return _reduced(*answer)


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
    numerator, denominator = _karp_mean(*parsed)
    return OUTPUT_BYTES, struct.pack("<qq", numerator, denominator)

"""Direct graph-path composition oracle, independent of the Link-Cut Tree."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MAX_Q, MODULUS, OUTPUT_ERROR,
    )
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        I64_MAX, I64_MIN, INVALID, MAX_INPUT_LENGTH, MAX_N, MAX_Q, MODULUS, OUTPUT_ERROR,
    )


def _path(adjacency: list[set[int]], start: int, target: int) -> list[int] | None:
    parent = [-1] * len(adjacency)
    parent[start] = start
    pending = [start]
    while pending and parent[target] < 0:
        vertex = pending.pop()
        for neighbor in adjacency[vertex]:
            if parent[neighbor] < 0:
                parent[neighbor] = vertex
                pending.append(neighbor)
    if parent[target] < 0:
        return None
    reversed_path = []
    vertex = target
    while vertex != start:
        reversed_path.append(vertex)
        vertex = parent[vertex]
    reversed_path.append(start)
    return list(reversed(reversed_path))


def _evaluate(values: Sequence[int] | None, input_is_null: bool, input_length: int | None) -> list[int] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    if len(values) < 2 + 2 * n + 2 * (n - 1) + 4 * q:
        return None
    functions = []
    cursor = 2
    for _ in range(n):
        multiplier, addend = values[cursor : cursor + 2]
        cursor += 2
        if not 1 <= multiplier < MODULUS or not 0 <= addend < MODULUS:
            return None
        functions.append((multiplier, addend))

    adjacency = [set() for _ in range(n)]
    roots = list(range(n))

    def root(vertex: int) -> int:
        while roots[vertex] != vertex:
            roots[vertex] = roots[roots[vertex]]
            vertex = roots[vertex]
        return vertex

    for _ in range(n - 1):
        u, v = values[cursor : cursor + 2]
        cursor += 2
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        root_u, root_v = root(u), root(v)
        if root_u == root_v:
            return None
        roots[root_v] = root_u
        adjacency[u].add(v)
        adjacency[v].add(u)

    queries = []
    for _ in range(q):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        width = 5 if kind == 0 else 4 if kind in (1, 2) else 0
        if width == 0 or cursor + width > len(values):
            return None
        query = tuple(values[cursor : cursor + width])
        cursor += width
        if kind == 0:
            _, u, v, w, x = query
            if not all(0 <= vertex < n for vertex in (u, v, w, x)) or u == v or w == x or v not in adjacency[u]:
                return None
            adjacency[u].remove(v)
            adjacency[v].remove(u)
            if _path(adjacency, w, x) is not None:
                return None
            adjacency[w].add(x)
            adjacency[x].add(w)
        elif kind == 1:
            _, vertex, multiplier, addend = query
            if not 0 <= vertex < n or not 1 <= multiplier < MODULUS or not 0 <= addend < MODULUS:
                return None
            functions[vertex] = (multiplier, addend)
        else:
            _, u, v, argument = query
            if not 0 <= u < n or not 0 <= v < n or not 0 <= argument < MODULUS:
                return None
            vertices = _path(adjacency, u, v)
            if vertices is None:
                return None
            result = argument
            for vertex in vertices:
                multiplier, addend = functions[vertex]
                result = (multiplier * result + addend) % MODULUS
            queries.append(result)
    if cursor != len(values):
        return None
    return queries


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID, b""
    answers = _evaluate(values, input_is_null, input_length)
    if answers is None:
        return INVALID, b""
    required = 8 * len(answers)
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR, b""
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload

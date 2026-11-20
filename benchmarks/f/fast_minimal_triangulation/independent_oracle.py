"""Set-based recursive FMT reference with explicit edge-set serialization."""
from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import (MAX_N, MAX_M, MAX_VALID_INPUT_LENGTH,
                             MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES,
                             WORKSPACE_BYTES)


def _decode(values: Sequence[int]):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges = []
    last = (-1, -1)
    for pos in range(m):
        edge = (values[2 + 2 * pos], values[3 + 2 * pos])
        if not 0 <= edge[0] < edge[1] < n or edge <= last:
            return None
        edges.append(edge)
        last = edge
    return n, set(edges)


def _run(vertices: frozenset[int], edges: frozenset[tuple[int, int]]) -> set[tuple[int, int]]:
    def has(u: int, v: int) -> bool:
        return (min(u, v), max(u, v)) in edges

    if all(has(u, v) for u in vertices for v in vertices if u < v):
        return set()
    pivot = min(u for u in vertices
                if any(not has(u, v) for v in vertices if v != u))
    region = frozenset({pivot} | {v for v in vertices if v != pivot and has(pivot, v)})
    remainder = set(vertices - region)
    components: list[frozenset[int]] = []
    while remainder:
        seed = min(remainder)
        reached = {seed}
        frontier = [seed]
        remainder.remove(seed)
        while frontier:
            u = frontier.pop()
            for v in sorted(tuple(remainder)):
                if has(u, v):
                    remainder.remove(v)
                    reached.add(v)
                    frontier.append(v)
        components.append(frozenset(reached))

    saturated = set(edges)
    added: set[tuple[int, int]] = set()
    closures = []
    for comp in components:
        boundary = {v for u in comp for v in vertices - comp if has(u, v)}
        ordered = sorted(boundary)
        for i, u in enumerate(ordered):
            for v in ordered[i + 1:]:
                pair = (u, v)
                if pair not in saturated:
                    saturated.add(pair)
                    added.add(pair)
        closures.append(frozenset(comp | boundary))
    frozen_edges = frozenset(saturated)
    added.update(_run(region, frozen_edges))
    for closure in closures:
        added.update(_run(closure, frozen_edges))
    return added


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    completion = sorted(_run(frozenset(range(n)), frozenset(edges)) - edges)
    payload = struct.pack("<" + "q" * (1 + 2 * len(completion)), len(completion),
                          *(x for edge in completion for x in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]

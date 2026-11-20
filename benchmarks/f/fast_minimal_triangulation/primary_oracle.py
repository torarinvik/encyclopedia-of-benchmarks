"""Bounded recursive FMT with component-neighborhood saturation."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 28
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_M)
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int]):
    if len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    previous = (-1, -1)
    for i in range(m):
        u, v = values[2 + 2 * i:4 + 2 * i]
        if not (0 <= u < v < n) or (u, v) <= previous:
            return None
        previous = (u, v)
        edges.append((u, v))
    return n, edges


def _fmt(vertices: tuple[int, ...], graph: tuple[int, ...]) -> int:
    """Return added undirected edges as bits indexed by u*8+v, u<v."""
    if len(vertices) <= 1 or all(
        all((graph[u] >> v) & 1 for v in vertices if v != u)
        for u in vertices
    ):
        return 0

    # Deterministic singleton K: lowest-ID vertex not universal in this subproblem.
    pivot = next(u for u in vertices if any(not ((graph[u] >> v) & 1)
                                             for v in vertices if v != u))
    a = tuple(u for u in vertices if u == pivot or ((graph[pivot] >> u) & 1))
    a_set = set(a)
    outside = tuple(u for u in vertices if u not in a_set)

    # Find components of G - A in ascending seed/neighbor order.
    unseen = set(outside)
    components: list[tuple[int, ...]] = []
    while unseen:
        seed = min(unseen)
        unseen.remove(seed)
        queue = [seed]
        for u in queue:
            for v in sorted(tuple(unseen)):
                if (graph[u] >> v) & 1:
                    unseen.remove(v)
                    queue.append(v)
        components.append(tuple(sorted(queue)))

    updated = list(graph)
    saturation = 0
    closures: list[tuple[int, ...]] = []
    for component in components:
        cset = set(component)
        boundary = tuple(sorted({v for u in component for v in vertices
                                 if v not in cset and ((updated[u] >> v) & 1)}))
        closures.append(tuple(sorted(cset | set(boundary))))
        for i, u in enumerate(boundary):
            for v in boundary[i + 1:]:
                if not ((updated[u] >> v) & 1):
                    updated[u] |= 1 << v
                    updated[v] |= 1 << u
                    x, y = (u, v) if u < v else (v, u)
                    saturation |= 1 << (x * MAX_N + y)

    final_graph = tuple(updated)
    result = saturation | _fmt(a, final_graph)
    for closure in closures:
        result |= _fmt(closure, final_graph)
    return result


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, edges = parsed
    graph = [0] * MAX_N
    original = 0
    for u, v in edges:
        graph[u] |= 1 << v
        graph[v] |= 1 << u
        original |= 1 << (u * MAX_N + v)
    added = _fmt(tuple(range(n)), tuple(graph)) & ~original
    chosen = [(u, v) for u in range(n) for v in range(u + 1, n)
              if (added >> (u * MAX_N + v)) & 1]
    payload = struct.pack("<" + "q" * (1 + 2 * len(chosen)), len(chosen),
                          *(x for edge in chosen for x in edge))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]

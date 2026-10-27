"""Primary Dijkstra oracle for the chapter's bounded Greedy-1 UFP profile."""
from __future__ import annotations

from collections.abc import Sequence
import math

MAX_N = 8
MAX_M = 16
MAX_K = 8
MAX_INPUT = 75
MAX_OUTPUT = 648
EULER = 2.718281828459045


def _parse(values, input_is_null, input_length):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 9 or len(values) > MAX_INPUT
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m, k = values[:3]
    if not 2 <= n <= MAX_N or not 1 <= m <= MAX_M or not 1 <= k <= MAX_K or len(values) != 3 + 3*m + 3*k:
        return None
    edges = []
    previous = None
    for e in range(m):
        u, v, cap = values[3+3*e:6+3*e]
        if not 0 <= u < v < n or not 2 <= cap <= 8 or previous is not None and (u, v) <= previous:
            return None
        previous = (u, v)
        edges.append((u, v, cap))
    commodities = []
    for i in range(k):
        s, t, value = values[3+3*m+3*i:6+3*m+3*i]
        if not 0 <= s < n or not 0 <= t < n or s == t or not 1 <= value <= 100:
            return None
        commodities.append((s, t, value))
    return n, edges, commodities


def _shortest(n, edges, prices, source, target):
    dist = [math.inf] * n
    parent = [-1] * n
    used = [False] * n
    dist[source] = 0.0
    for _ in range(n):
        u = -1
        for v in range(n):
            if not used[v] and (u < 0 or dist[v] < dist[u] or dist[v] == dist[u] and v < u):
                u = v
        if u < 0 or not math.isfinite(dist[u]):
            break
        used[u] = True
        for e, (a, b, _) in enumerate(edges):
            v = b if a == u else a if b == u else -1
            if v < 0 or used[v]:
                continue
            candidate = dist[u] + prices[e]
            if candidate < dist[v] or candidate == dist[v] and (parent[v] < 0 or u < parent[v]):
                dist[v] = candidate
                parent[v] = u
    if not math.isfinite(dist[target]):
        return None
    reverse = []
    v = target
    while v != source and len(reverse) < n:
        reverse.append(v)
        v = parent[v]
        if v < 0:
            return None
    if v != source or len(reverse) >= n:
        return None
    reverse.append(source)
    return dist[target], list(reversed(reverse))


def _solve(parsed):
    n, edges, commodities = parsed
    capacities = [edge[2] for edge in edges]
    B = min(capacities)
    threshold = math.pow(EULER, B - 1) * len(edges)
    prices = [1.0 / b for b in capacities]
    live = [True] * len(commodities)
    selected = []
    while any(live):
        best = -1
        best_score = -1.0
        routes = [None] * len(commodities)
        for i, (source, target, value) in enumerate(commodities):
            if not live[i]:
                continue
            route = _shortest(n, edges, prices, source, target)
            if route is None:
                return None
            routes[i] = route[1]
            score = value / route[0]  # the bounded profile fixes each demand to one
            if best < 0 or score > best_score:
                best, best_score = i, score
        if best < 0:
            break
        path = routes[best]
        selected.append((best, path))
        live[best] = False
        for u, v in zip(path, path[1:]):
            for e, (a, b, cap) in enumerate(edges):
                if (a == u and b == v) or (a == v and b == u):
                    prices[e] *= math.pow(threshold, 1.0 / (cap - 1))
                    break
        if sum(cap * prices[e] for e, (_, _, cap) in enumerate(edges)) >= threshold:
            break
    result = [len(selected)]
    for commodity, path in selected:
        result.extend((commodity, len(path), *path))
    return result


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    result = _solve(parsed)
    if result is None:
        return -1, b""
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload

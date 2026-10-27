"""Independent Bellman-Ford verifier oracle for Greedy-1 UFP."""
from __future__ import annotations

from collections.abc import Sequence
import math


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 9 or len(values) > 75
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n, m, k = values[:3]
    if not 2 <= n <= 8 or not 1 <= m <= 16 or not 1 <= k <= 8 or len(values) != 3+3*m+3*k:
        return -1, b""
    edges = []
    last = None
    for e in range(m):
        u, v, cap = values[3+3*e:6+3*e]
        if not 0 <= u < v < n or not 2 <= cap <= 8 or last is not None and (u, v) <= last:
            return -1, b""
        last = (u, v)
        edges.append((u, v, cap))
    commodities = []
    for i in range(k):
        s, t, value = values[3+3*m+3*i:6+3*m+3*i]
        if not 0 <= s < n or not 0 <= t < n or s == t or not 1 <= value <= 100:
            return -1, b""
        commodities.append((s, t, value))
    capacities = [edge[2] for edge in edges]
    B = min(capacities)
    # Direct-log evaluation and repeated edge relaxations are independent of Dijkstra.
    threshold = math.exp((B-1) * math.log(2.718281828459045)) * m
    prices = [1.0 / b for b in capacities]
    active = [True] * k
    chosen = []
    while any(active):
        route_data = [None] * k
        best = -1
        best_score = -1.0
        for i, (source, target, value) in enumerate(commodities):
            if not active[i]:
                continue
            dist = [math.inf] * n
            parent = [-1] * n
            dist[source] = 0.0
            for _ in range(n-1):
                changed = False
                for e, (u, v, _) in enumerate(edges):
                    for x, y in ((u, v), (v, u)):
                        if math.isfinite(dist[x]):
                            candidate = dist[x] + prices[e]
                            if candidate < dist[y] or candidate == dist[y] and (parent[y] < 0 or x < parent[y]):
                                dist[y] = candidate
                                parent[y] = x
                                changed = True
                if not changed:
                    break
            if not math.isfinite(dist[target]):
                return -1, b""
            reverse = []
            node = target
            while node != source and len(reverse) < n:
                reverse.append(node)
                node = parent[node]
                if node < 0:
                    return -1, b""
            if node != source or len(reverse) >= n:
                return -1, b""
            reverse.append(source)
            path = list(reversed(reverse))
            route_data[i] = path
            score = value / dist[target]
            if best < 0 or score > best_score:
                best, best_score = i, score
        if best < 0:
            break
        path = route_data[best]
        chosen.append((best, path))
        active[best] = False
        for u, v in zip(path, path[1:]):
            for e, (a, b, cap) in enumerate(edges):
                if (a == u and b == v) or (a == v and b == u):
                    prices[e] *= math.exp(math.log(threshold) / (cap-1))
                    break
        total = 0.0
        for e, (_, _, cap) in enumerate(edges):
            total += cap * prices[e]
        if total >= threshold:
            break
    words = [len(chosen)]
    for commodity, path in chosen:
        words.extend((commodity, len(path), *path))
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in words)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload

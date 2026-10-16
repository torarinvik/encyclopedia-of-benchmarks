"""Cut-enumeration oracle for the bounded Gomory-Hu tree signature."""

from __future__ import annotations

MAX_VERTICES = 8
MAX_CAPACITY = 1000
MAX_INPUT_LENGTH = 1 + MAX_VERTICES * MAX_VERTICES
MASK64 = (1 << 64) - 1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1
    n = values[0]
    if not 1 <= n <= MAX_VERTICES or len(values) != 1 + n * n:
        return -1
    cap = values[1:]
    for u in range(n):
        for v in range(n):
            c = cap[u * n + v]
            if not 0 <= c <= MAX_CAPACITY or (u == v and c != 0) or c != cap[v * n + u]:
                return -1

    cuts = [0] * (n * n)
    for s in range(n):
        for t in range(s + 1, n):
            best = sum(cap[s * n + v] for v in range(n))
            for side in range(1 << n):
                if not (side & (1 << s)) or side & (1 << t):
                    continue
                total = 0
                for u in range(n):
                    for v in range(n):
                        if (side >> u & 1) != (side >> v & 1):
                            total += cap[u * n + v]
                best = min(best, total // 2)
            cuts[s * n + t] = cuts[t * n + s] = best
    h = 14695981039346656037
    for value in cuts:
        bits = value
        for _ in range(8):
            h = ((h ^ (bits & 255)) * 1099511628211) & MASK64
            bits >>= 8
    return h if h < 1 << 63 else h - (1 << 64)

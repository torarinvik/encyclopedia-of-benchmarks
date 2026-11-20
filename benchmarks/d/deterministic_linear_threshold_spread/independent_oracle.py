"""Full-scan synchronous reference for deterministic threshold spread."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OUTPUT_BYTES = 80
WORKSPACE_BYTES = 2048


def _frame(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > 92
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m, s = values[0], values[1], values[2]
    if not 1 <= n <= 8 or not 0 <= m <= 24 or not 0 <= s <= n:
        return None
    if len(values) != 3 + s + 3 * m + n:
        return None
    seeds = values[3:3 + s]
    if any(v < 0 or v >= n for v in seeds) or len(set(seeds)) != s:
        return None
    start = 3 + s
    edges = []
    seen = set()
    incoming = [0] * n
    for i in range(m):
        u, v, weight = values[start + 3 * i:start + 3 * i + 3]
        if u < 0 or u >= n or v < 0 or v >= n or u == v or not 0 <= weight <= 16 or (u, v) in seen:
            return None
        seen.add((u, v))
        incoming[v] += weight
        if incoming[v] > 16:
            return None
        edges.append((u, v, weight))
    thresholds = list(values[start + 3 * m:])
    if len(thresholds) != n or any(t < 1 or t > 16 for t in thresholds):
        return None
    return n, list(seeds), edges, thresholds


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _frame(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, seeds, edges, thresholds = parsed
    activation_round = [-1] * n
    active = [False] * n
    for seed in seeds:
        active[seed] = True
        activation_round[seed] = 0

    wave_count = 0
    while True:
        newly_active = []
        for target in range(n):
            if active[target]:
                continue
            received = 0
            for source, endpoint, weight in edges:
                if endpoint == target and active[source]:
                    received += weight
            if received >= thresholds[target]:
                newly_active.append(target)
        if not newly_active:
            break
        wave_count += 1
        for target in newly_active:
            active[target] = True
            activation_round[target] = wave_count

    words = [n, wave_count, *activation_round]
    payload = b"".join(value.to_bytes(8, "little", signed=True) for value in words)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

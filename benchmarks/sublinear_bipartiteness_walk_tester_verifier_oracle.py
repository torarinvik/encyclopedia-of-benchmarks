"""Independent bitset-neighbor verifier for the supplied random-walk trace."""

from __future__ import annotations

from collections.abc import Sequence


def _encode(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) < 8 or len(values) > 330
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, d, m = values[:3]
    if not 1 <= n <= 16 or not 3 <= d <= 4 or not 0 <= m <= min(32, n * d // 2):
        return -1, b""
    suffix = 3 + 2 * m
    if len(values) < suffix + 4:
        return -1, b""
    t, r, length = values[suffix:suffix + 3]
    if not 1 <= t <= 4 or not 1 <= r <= 8 or not 1 <= length <= 8:
        return -1, b""
    if len(values) != suffix + 3 + t + t * r * length:
        return -1, b""
    adjacency = [0] * n
    edges_seen: set[tuple[int, int]] = set()
    for edge_index in range(m):
        u, v = values[3 + 2 * edge_index:5 + 2 * edge_index]
        if not 0 <= u < v < n or (u, v) in edges_seen:
            return -1, b""
        edges_seen.add((u, v))
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u
    for vertex in range(n):
        if adjacency[vertex].bit_count() > d:
            return -1, b""
    starts_at = suffix + 3
    draw_at = starts_at + t
    starts = values[starts_at:draw_at]
    draws = values[draw_at:]
    if any(not 0 <= start < n for start in starts) or any(not 0 <= x < 2 * d for x in draws):
        return -1, b""

    accepted = 1
    action = 0
    for start in starts:
        parity_masks = [0] * n
        parity_masks[start] = 1
        for _ in range(r):
            node = start
            odd = 0
            for _ in range(length):
                slot = draws[action]
                action += 1
                if slot < adjacency[node].bit_count():
                    remaining = adjacency[node]
                    for _ in range(slot):
                        remaining &= remaining - 1
                    lowest = remaining & -remaining
                    node = lowest.bit_length() - 1
                    odd ^= 1
                parity_masks[node] |= 1 << odd
                if parity_masks[node] == 3:
                    accepted = 0
                    break
            if not accepted:
                break
        if not accepted:
            break
    payload = _encode(accepted)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload

"""Independent reference by enumerating every allowable deletion subset."""

from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import (
    MAX_CLIENTS, MAX_DRAWS, MAX_FACILITIES, MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))):
        return None
    if (len(values) < 12 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    n, f, q, raw_mask = values[:4]
    if not (1 <= n <= MAX_CLIENTS and 1 <= f <= MAX_FACILITIES
            and 1 <= q <= MAX_DRAWS and 0 < raw_mask < (1 << f)):
        return None
    p = n + f
    if len(values) != 4 + 2 * n + p * p + f + q:
        return None
    at = 4
    assigned = list(values[at:at + n]); at += n
    weights = list(values[at:at + n]); at += n
    if any(not 0 <= x < f or not raw_mask & (1 << x) for x in assigned): return None
    if any(not 1 <= x <= 10 for x in weights): return None
    dist = list(values[at:at + p * p]); at += p * p
    if any(not 0 <= x <= 1000 for x in dist): return None
    for a in range(p):
        if dist[a * p + a] != 0: return None
        for b in range(p):
            if a != b and dist[a * p + b] == 0: return None
            if dist[a * p + b] != dist[b * p + a]: return None
            for c in range(p):
                if dist[a * p + b] > dist[a * p + c] + dist[c * p + b]: return None
    fees = list(values[at:at + f]); at += f
    draws = list(values[at:at + q])
    if any(not 0 <= x <= 1000 for x in fees) or any(not 0 <= x < f for x in draws): return None
    return n, f, q, raw_mask, assigned, weights, dist, fees, draws


def _cost(n, f, mask, assigned, weights, dist, fees):
    p = n + f
    return (sum(fees[s] for s in range(f) if mask & (1 << s))
            + sum(weights[j] * dist[j * p + n + assigned[j]] for j in range(n)))


def expected_output(values: Sequence[int] | None, *, capacity: int | None = None,
                    input_length: int | None = None, input_is_null: bool = False,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None: return -1, b""
    n, f, q, mask, assigned, weights, dist, fees, draws = parsed
    p = n + f
    current = _cost(n, f, mask, assigned, weights, dist, fees)
    trace_cost: list[int] = []
    trace_accept: list[int] = []
    accept_count = 0
    for candidate in draws:
        did_accept = 0
        bit = 1 << candidate
        if not mask & bit:
            closer = [dist[j * p + n + candidate] < dist[j * p + n + assigned[j]]
                      for j in range(n)]
            best_cost = current
            best_drop = 0
            best_assignment = assigned[:]
            # Only current open facilities can be dropped. Directly score each subset.
            subset = mask
            while True:
                next_assignment = [candidate if closer[j] or (subset & (1 << assigned[j]))
                                   else assigned[j] for j in range(n)]
                next_mask = (mask | bit) & ~subset
                value = _cost(n, f, next_mask, next_assignment, weights, dist, fees)
                if value < best_cost or (value == best_cost and subset < best_drop):
                    best_cost, best_drop, best_assignment = value, subset, next_assignment
                if subset == 0: break
                subset = (subset - 1) & mask
            if best_cost < current:
                assigned = best_assignment
                mask = (mask | bit) & ~best_drop
                current = best_cost
                did_accept = 1
                accept_count += 1
        trace_cost.append(current)
        trace_accept.append(did_accept)
    words = trace_cost + trace_accept + [current, mask] + assigned + [accept_count]
    needed = 8 * len(words)
    if type(output_is_null) is not bool: return -1, b""
    if output_is_null or (capacity is not None and (type(capacity) is not int or capacity < needed)):
        return -2, b""
    return needed, b"".join(struct.pack("<q", word) for word in words)

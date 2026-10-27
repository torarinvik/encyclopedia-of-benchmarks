"""Primary exact-integer oracle for the bounded DOI323 sink estimator trace."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_H = 8
SCALE = 1_000_000
MAX_INPUT = 82


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 4 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, horizon = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= horizon <= MAX_H:
        return None
    if len(values) != 2 + n + horizon + n * horizon:
        return None
    lambdas = list(values[2:2 + n])
    if any(value < 0 or value > SCALE for value in lambdas) or sum(lambdas) != SCALE:
        return None
    full = (1 << n) - 1
    path_start = 2 + n
    paths = list(values[path_start:path_start + horizon])
    if any(mask <= 0 or mask & ~full for mask in paths):
        return None
    draws = list(values[path_start + horizon:])
    scale = SCALE * math.lcm(*range(1, horizon + 1))
    if any(draw < 0 or draw >= scale for draw in draws):
        return None
    return n, horizon, lambdas, paths, draws, scale


def _solve(parsed):
    n, horizon, lambdas, paths, draws, scale = parsed
    denominator_lcm = scale // SCALE
    state = [value * denominator_lcm for value in lambdas]
    for observation in range(horizon):
        divisor = observation + 1  # NbrLoop is read before the post-vector increment.
        delta_scale = scale // divisor
        for slice_index in range(n):
            current = state[slice_index]
            if current < 0 or current > scale:
                return None
            draw = draws[observation * n + slice_index]
            bernoulli = 1 if draw < current else 0
            observed = (paths[observation] >> slice_index) & 1
            updated = current + (observed - bernoulli) * delta_scale
            if updated < 0 or updated > scale:
                return None
            state[slice_index] = updated
    return [scale, *state]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    fields = _solve(parsed)
    if fields is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

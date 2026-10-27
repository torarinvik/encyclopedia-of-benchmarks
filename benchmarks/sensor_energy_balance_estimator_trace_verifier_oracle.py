"""Independent Fraction-based verifier for the DOI323 sink estimator trace."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from fractions import Fraction

SCALE = 1_000_000


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 82)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if (input_is_null or not isinstance(values, (tuple, list)) or not 4 <= len(values) <= 82
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    n, horizon = values[:2]
    if not 1 <= n <= 8 or not 1 <= horizon <= 8 or len(values) != 2 + n + horizon + n * horizon:
        return -1, b""
    lambdas = values[2:2 + n]
    if any(value < 0 or value > SCALE for value in lambdas) or sum(lambdas) != SCALE:
        return -1, b""
    full = (1 << n) - 1
    path_start = 2 + n
    paths = values[path_start:path_start + horizon]
    if any(mask <= 0 or mask & ~full for mask in paths):
        return -1, b""
    draws = values[path_start + horizon:]
    q = SCALE * math.lcm(*range(1, horizon + 1))
    if any(draw < 0 or draw >= q for draw in draws):
        return -1, b""

    state = [Fraction(value, SCALE) for value in lambdas]
    for observation in range(horizon):
        loop_count = observation + 1
        for slice_index in range(n):
            current = state[slice_index]
            if current < 0 or current > 1:
                return -1, b""
            draw = draws[observation * n + slice_index]
            bernoulli = 1 if Fraction(draw, q) < current else 0
            observed = (paths[observation] >> slice_index) & 1
            updated = current + Fraction(observed - bernoulli, loop_count)
            if updated < 0 or updated > 1:
                return -1, b""
            state[slice_index] = updated

    fields = [q, *(int(value * q) for value in state)]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

"""Independent sorted-prefix verifier for the bounded secretary rule."""

from __future__ import annotations

import struct
from collections.abc import Sequence

N_LIMIT = 16
MAX_INPUT = 17
OBSERVE = {3: 1, 4: 1, 5: 1, 6: 2, 7: 2, 8: 2, 9: 3, 10: 3,
           11: 4, 12: 4, 13: 4, 14: 5, 15: 5, 16: 5}


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 4 <= len(values) <= MAX_INPUT
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    n = values[0]
    if n not in range(3, N_LIMIT + 1) or len(values) != n + 1:
        return None
    ranks = tuple(values[1:])
    if len(set(ranks)) != n or min(ranks) != 1 or max(ranks) != n:
        return None
    return ranks, OBSERVE[n]


def _run(decoded) -> int:
    ranks, observed = decoded
    ordered_sample = sorted(ranks[:observed])
    threshold = ordered_sample[-1]
    chosen = next((position for position in range(observed, len(ranks))
                   if ranks[position] > threshold), None)
    return -1 if chosen is None else chosen


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    payload = struct.pack("<q", _run(decoded))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

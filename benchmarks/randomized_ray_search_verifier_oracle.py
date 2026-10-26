"""Independent geometric-series verifier for supplied RaySearch randomness."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 11
MAX_OUTPUT_BYTES = 16
TICKS_PER_DISTANCE_UNIT = 1000


def _decode(data):
    if not isinstance(data, (tuple, list)) or not 5 <= len(data) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in data):
        return None
    rays, factor, initial = data[0], data[1], data[2]
    if not 2 <= rays <= 5 or not 2 <= factor <= 4:
        return None
    if not TICKS_PER_DISTANCE_UNIT <= initial < factor * TICKS_PER_DISTANCE_UNIT:
        return None
    if len(data) != rays + 5:
        return None
    order = tuple(data[3:3 + rays])
    goal_ray, goal_distance = data[3 + rays], data[4 + rays]
    if set(order) != set(range(rays)) or len(set(order)) != rays:
        return None
    if not 0 <= goal_ray < rays or not 1 <= goal_distance <= 1_000_000_000:
        return None
    return rays, factor, initial, order, goal_ray, goal_distance


def _payload(decoded):
    rays, factor, initial, order, goal_ray, goal_distance = decoded
    threshold_round = 0
    distance = initial
    while distance < goal_distance:
        distance *= factor
        threshold_round += 1
    target_phase = order.index(goal_ray)
    attempts_before_hit = threshold_round + (target_phase - threshold_round) % rays
    count = attempts_before_hit + 1
    failed_out_and_back = 2 * initial * ((factor ** attempts_before_hit - 1) // (factor - 1))
    return struct.pack("<qq", count, failed_out_and_back + goal_distance)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    payload = _payload(decoded)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

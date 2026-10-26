"""Exact supplied-randomness simulator for the chapter's RaySearch algorithm."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_RAYS = 5
MAX_ROUNDS = 32
MAX_INPUT_LENGTH = 11
TICKS_PER_DISTANCE_UNIT = 1000
MAX_OUTPUT_BYTES = 16


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    rays, growth, initial_ticks = values[:3]
    if not 2 <= rays <= MAX_RAYS or not 2 <= growth <= 4:
        return None
    if not TICKS_PER_DISTANCE_UNIT <= initial_ticks < growth * TICKS_PER_DISTANCE_UNIT:
        return None
    expected_length = rays + 5
    if len(values) != expected_length:
        return None
    permutation = list(values[3:3 + rays])
    target_ray, target_ticks = values[3 + rays:5 + rays]
    if sorted(permutation) != list(range(rays)):
        return None
    if not 0 <= target_ray < rays or not 1 <= target_ticks <= 1_000_000_000:
        return None
    return rays, growth, initial_ticks, permutation, target_ray, target_ticks


def _payload(parsed) -> bytes:
    rays, growth, distance, permutation, target_ray, target_distance = parsed
    total = 0
    for attempt in range(MAX_ROUNDS):
        ray = permutation[attempt % rays]
        if ray == target_ray and target_distance <= distance:
            total += target_distance
            return struct.pack("<qq", attempt + 1, total)
        total += 2 * distance
        distance *= growth
    raise AssertionError("bounded valid instance exceeded its search-round limit")


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _payload(parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

"""Portable reference contract for the bounded car-pooling benchmark."""

from __future__ import annotations

MAX_TRIPS = 64
MAX_INPUT_LENGTH = 2 + 3 * MAX_TRIPS


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    capacity, trip_count = values[:2]
    if not 0 <= capacity <= 1000 or not 0 <= trip_count <= MAX_TRIPS:
        return -1
    if len(values) != 2 + 3 * trip_count:
        return -1

    events = [0] * 1001
    for offset in range(2, len(values), 3):
        passengers, origin, destination = values[offset:offset + 3]
        if (not 1 <= passengers <= 1000 or not 0 <= origin < destination <= 1000):
            return -1
        events[origin] += passengers
        events[destination] -= passengers

    occupants = 0
    for position in range(1000):
        occupants += events[position]
        if occupants > capacity:
            return 0
    return 1

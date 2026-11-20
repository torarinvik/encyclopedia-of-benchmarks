"""Independent dynamic-programming oracle for minimum refueling stops."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    IMPOSSIBLE_RESULT,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_START_FUEL,
    MAX_STATION_FUEL,
    MAX_TARGET,
)


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    target, start_fuel, n = values[:3]
    if not 1 <= target <= MAX_TARGET or not 0 <= start_fuel <= MAX_START_FUEL:
        return None
    if not 0 <= n <= MAX_N or len(values) != 3 + 2 * n:
        return None
    stations: list[tuple[int, int]] = []
    previous = 0
    for i in range(n):
        position, fuel = values[3 + 2 * i:5 + 2 * i]
        if not previous < position < target or not 1 <= fuel <= MAX_STATION_FUEL:
            return None
        stations.append((position, fuel))
        previous = position
    return target, start_fuel, stations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    target, start_fuel, stations = decoded
    farthest = [-1] * (len(stations) + 1)
    farthest[0] = start_fuel
    for index, (position, fuel) in enumerate(stations):
        for stops in range(index + 1, 0, -1):
            previous_reach = farthest[stops - 1]
            if previous_reach >= position:
                farthest[stops] = max(farthest[stops], previous_reach + fuel)
    for stops, reach in enumerate(farthest):
        if reach >= target:
            return stops
    return IMPOSSIBLE_RESULT

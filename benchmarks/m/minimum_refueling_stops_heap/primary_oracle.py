"""Greedy maximum-refueling-stops oracle using a bounded max-heap."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_TARGET = 2000
MAX_START_FUEL = 2000
MAX_STATION_FUEL = 2000
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -2
IMPOSSIBLE_RESULT = -1


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
    cursor = 3
    for _ in range(n):
        position, fuel = values[cursor:cursor + 2]
        cursor += 2
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
    target, reach, stations = decoded
    heap: list[int] = []
    station_index = 0
    stops = 0

    while reach < target:
        while (station_index < len(stations)
               and stations[station_index][0] <= reach):
            fuel = stations[station_index][1]
            station_index += 1
            child = len(heap)
            heap.append(fuel)
            while child > 0:
                parent = (child - 1) // 2
                if heap[parent] >= heap[child]:
                    break
                heap[parent], heap[child] = heap[child], heap[parent]
                child = parent
        if not heap:
            return IMPOSSIBLE_RESULT
        best = heap[0]
        tail = heap.pop()
        if heap:
            heap[0] = tail
            parent = 0
            while True:
                left = 2 * parent + 1
                right = left + 1
                if left >= len(heap):
                    break
                child = left
                if right < len(heap) and heap[right] > heap[left]:
                    child = right
                if heap[parent] >= heap[child]:
                    break
                heap[parent], heap[child] = heap[child], heap[parent]
                parent = child
        reach += best
        stops += 1
    return stops

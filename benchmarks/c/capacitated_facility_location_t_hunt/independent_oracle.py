"""Independent T-Hunt reference by direct enumeration of every dropped-copy subset."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_CLIENTS = 4
MAX_FACILITY_TYPES = 3
MAX_OPEN_COPIES = 4
MAX_POINTS = MAX_CLIENTS + MAX_FACILITY_TYPES
MAX_VALID_INPUT_LENGTH = 4 + MAX_POINTS * MAX_POINTS + 2 * MAX_FACILITY_TYPES + MAX_OPEN_COPIES + MAX_CLIENTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 40


def _read_frame(values: Sequence[int] | None, input_is_null: bool,
                input_length: int | None) -> tuple[int, int, int, list[int], list[int], list[int],
                                                    list[int], list[int], int] | None:
    if type(input_is_null) is not bool or input_is_null or values is None:
        return None
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(word) is not int or word < -(1 << 63) or word >= (1 << 63) for word in values):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    n, facility_count, copy_count, target = values[:4]
    if not (1 <= n <= 4 and 1 <= facility_count <= 3 and 1 <= copy_count <= 4
            and 0 <= target < facility_count):
        return None
    order = n + facility_count
    expected_length = 4 + order * order + 2 * facility_count + copy_count + n
    if expected_length != len(values):
        return None
    offset = 4
    distance = values[offset:offset + order * order]
    offset += order * order
    for a in range(order):
        for b in range(order):
            value = distance[a * order + b]
            if value < 0 or value > 1000 or (a == b and value != 0):
                return None
            if a != b and value == 0:
                return None
            if value != distance[b * order + a]:
                return None
            for c in range(order):
                if value > distance[a * order + c] + distance[c * order + b]:
                    return None
    costs = list(values[offset:offset + facility_count])
    offset += facility_count
    caps = list(values[offset:offset + facility_count])
    offset += facility_count
    if any(cost < 0 or cost > 1000 for cost in costs):
        return None
    if any(cap < 1 or cap > n for cap in caps):
        return None
    types = list(values[offset:offset + copy_count])
    offset += copy_count
    assigned = list(values[offset:offset + n])
    if any(kind < 0 or kind >= facility_count for kind in types):
        return None
    if any(copy < 0 or copy >= copy_count for copy in assigned):
        return None
    counts = [assigned.count(copy) for copy in range(copy_count)]
    if any(counts[copy] > caps[types[copy]] for copy in range(copy_count)):
        return None
    return n, facility_count, copy_count, list(distance), costs, caps, types, assigned, target


def _enumerated_result(frame: tuple[int, int, int, list[int], list[int], list[int],
                                      list[int], list[int], int]) -> tuple[int, int, int, int, int]:
    n, facility_count, copy_count, distance, costs, caps, types, assigned, target = frame
    point_count = n + facility_count
    item_weight = [0] * copy_count
    item_profit = [costs[types[i]] for i in range(copy_count)]
    current_cost = sum(costs[kind] for kind in types)
    for client in range(n):
        copy = assigned[client]
        item_weight[copy] += 1
        prior = distance[client * point_count + n + types[copy]]
        replacement = distance[client * point_count + n + target]
        current_cost += prior
        item_profit[copy] -= replacement - prior

    for copies_added in range(1, n + 1):
        limit = copies_added * caps[target]
        maximum_profit: int | None = None
        selected_mask = 0
        for mask in range(1 << copy_count):
            weight = 0
            profit = 0
            for item in range(copy_count):
                if mask & (1 << item):
                    weight += item_weight[item]
                    profit += item_profit[item]
            if weight > limit:
                continue
            if (maximum_profit is None or profit > maximum_profit
                    or (profit == maximum_profit and mask < selected_mask)):
                maximum_profit = profit
                selected_mask = mask
        assert maximum_profit is not None
        if maximum_profit > copies_added * costs[target]:
            return (1, copies_added, selected_mask, current_cost,
                    current_cost + copies_added * costs[target] - maximum_profit)
    return (0, 0, 0, current_cost, current_cost)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    frame = _read_frame(values, input_is_null, input_length)
    if frame is None:
        return -1, b""
    if type(output_is_null) is not bool or output_is_null:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    return MAX_OUTPUT_BYTES, struct.pack("<5q", *_enumerated_result(frame))

"""Primary bounded T-Hunt reference using profit knapsack dynamic programming."""

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
_NEGATIVE_INFINITY = -(1 << 60)


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, int, int, list[int], list[int], list[int],
                                           list[int], list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))):
        return None
    if (len(values) < 4 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    n, facility_count, copy_count, target = values[:4]
    if not (1 <= n <= MAX_CLIENTS and 1 <= facility_count <= MAX_FACILITY_TYPES
            and 1 <= copy_count <= MAX_OPEN_COPIES and 0 <= target < facility_count):
        return None
    point_count = n + facility_count
    expected = 4 + point_count * point_count + 2 * facility_count + copy_count + n
    if len(values) != expected:
        return None
    at = 4
    metric = list(values[at:at + point_count * point_count])
    at += point_count * point_count
    if any(distance < 0 or distance > 1000 for distance in metric):
        return None
    for i in range(point_count):
        if metric[i * point_count + i] != 0:
            return None
        for j in range(point_count):
            ij = metric[i * point_count + j]
            if i != j and ij == 0:
                return None
            if ij != metric[j * point_count + i]:
                return None
            for k in range(point_count):
                if ij > metric[i * point_count + k] + metric[k * point_count + j]:
                    return None
    opening = list(values[at:at + facility_count])
    at += facility_count
    capacities = list(values[at:at + facility_count])
    at += facility_count
    if any(fee < 0 or fee > 1000 for fee in opening):
        return None
    if any(capacity < 1 or capacity > n for capacity in capacities):
        return None
    copy_types = list(values[at:at + copy_count])
    at += copy_count
    assignments = list(values[at:at + n])
    if any(kind < 0 or kind >= facility_count for kind in copy_types):
        return None
    if any(copy < 0 or copy >= copy_count for copy in assignments):
        return None
    loads = [0] * copy_count
    for copy in assignments:
        loads[copy] += 1
    if any(loads[copy] > capacities[copy_types[copy]] for copy in range(copy_count)):
        return None
    return n, facility_count, copy_count, metric, opening, capacities, copy_types, assignments, target


def _solve_dp(n: int, facility_count: int, copy_count: int, metric: list[int],
              opening: list[int], capacities: list[int], copy_types: list[int],
              assignments: list[int], target: int) -> tuple[int, int, int, int, int]:
    point_count = n + facility_count
    loads = [0] * copy_count
    profits = [opening[copy_types[copy]] for copy in range(copy_count)]
    old_cost = sum(opening[kind] for kind in copy_types)
    for client, copy in enumerate(assignments):
        loads[copy] += 1
        old_distance = metric[client * point_count + n + copy_types[copy]]
        target_distance = metric[client * point_count + n + target]
        old_cost += old_distance
        profits[copy] -= target_distance - old_distance

    chosen_l = 0
    chosen_mask = 0
    chosen_new_cost = old_cost
    for copies_added in range(1, n + 1):
        capacity_limit = min(n, copies_added * capacities[target])
        dp_profit = [_NEGATIVE_INFINITY] * (capacity_limit + 1)
        dp_mask = [0] * (capacity_limit + 1)
        dp_profit[0] = 0
        for item in range(copy_count):
            next_profit = dp_profit.copy()
            next_mask = dp_mask.copy()
            weight = loads[item]
            if weight <= capacity_limit:
                for used in range(capacity_limit + 1 - weight):
                    if dp_profit[used] == _NEGATIVE_INFINITY:
                        continue
                    new_weight = used + weight
                    value = dp_profit[used] + profits[item]
                    mask = dp_mask[used] | (1 << item)
                    if (value > next_profit[new_weight]
                            or (value == next_profit[new_weight] and mask < next_mask[new_weight])):
                        next_profit[new_weight] = value
                        next_mask[new_weight] = mask
            dp_profit, dp_mask = next_profit, next_mask
        best_profit = _NEGATIVE_INFINITY
        best_mask = 0
        for used, value in enumerate(dp_profit):
            mask = dp_mask[used]
            if value > best_profit or (value == best_profit and mask < best_mask):
                best_profit, best_mask = value, mask
        if best_profit > copies_added * opening[target]:
            chosen_l = copies_added
            chosen_mask = best_mask
            chosen_new_cost = old_cost + copies_added * opening[target] - best_profit
            break
    return (int(chosen_l != 0), chosen_l, chosen_mask, old_cost, chosen_new_cost)


def _pack(words: tuple[int, int, int, int, int]) -> bytes:
    return struct.pack("<5q", *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return a fixed 40-byte T-Hunt result or the byte-output ABI error."""
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    words = _solve_dp(*parsed)
    if type(output_is_null) is not bool or output_is_null:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    return MAX_OUTPUT_BYTES, _pack(words)

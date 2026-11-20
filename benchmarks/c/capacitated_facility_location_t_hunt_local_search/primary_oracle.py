"""Primary bounded outer-loop reference for capacitated T-Hunt local search."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_CLIENTS = 4
MAX_FACILITY_TYPES = 3
MAX_INITIAL_COPIES = 4
MAX_DISTANCE = 20
MAX_OPENING_FEE = 20
MAX_POINTS = MAX_CLIENTS + MAX_FACILITY_TYPES
MAX_VALID_INPUT_LENGTH = 3 + MAX_POINTS * MAX_POINTS + 2 * MAX_FACILITY_TYPES + MAX_INITIAL_COPIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_INITIAL_OBJECTIVE = MAX_INITIAL_COPIES * MAX_OPENING_FEE + MAX_CLIENTS * MAX_DISTANCE
MAX_ACCEPTED_STEPS = MAX_INITIAL_OBJECTIVE
MAX_FINAL_COPIES = MAX_INITIAL_COPIES + MAX_CLIENTS * MAX_ACCEPTED_STEPS
MAX_OUTPUT_BYTES = 8 * (3 + MAX_FINAL_COPIES + MAX_CLIENTS)


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))):
        return None
    if (len(values) < 10 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, facility_count, initial_copy_count = values[:3]
    if not (1 <= n <= MAX_CLIENTS and 1 <= facility_count <= MAX_FACILITY_TYPES
            and 1 <= initial_copy_count <= MAX_INITIAL_COPIES):
        return None
    point_count = n + facility_count
    expected = 3 + point_count * point_count + 2 * facility_count + initial_copy_count
    if len(values) != expected:
        return None
    at = 3
    metric = list(values[at:at + point_count * point_count])
    at += point_count * point_count
    if any(distance < 0 or distance > MAX_DISTANCE for distance in metric):
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
    fees = list(values[at:at + facility_count])
    at += facility_count
    capacities = list(values[at:at + facility_count])
    at += facility_count
    if any(fee < 0 or fee > MAX_OPENING_FEE for fee in fees):
        return None
    if any(capacity < 1 or capacity > n for capacity in capacities):
        return None
    copy_types = list(values[at:at + initial_copy_count])
    if any(kind < 0 or kind >= facility_count for kind in copy_types):
        return None
    copy_types.sort()
    if sum(capacities[kind] for kind in copy_types) < n:
        return None
    return n, facility_count, metric, fees, capacities, copy_types


def _canonical_assignment(n: int, facility_count: int, metric: list[int], fees: list[int],
                          capacities: list[int], copy_types: list[int]
                          ) -> tuple[int, list[int], list[int]]:
    """Find the minimum-cost assignment by type, then pack it into copy IDs."""
    point_count = n + facility_count
    multiplicity = [0] * facility_count
    for kind in copy_types:
        multiplicity[kind] += 1
    best_cost: int | None = None
    best_types: tuple[int, ...] | None = None
    for types in itertools.product(range(facility_count), repeat=n):
        loads = [0] * facility_count
        service = 0
        for client, kind in enumerate(types):
            loads[kind] += 1
            service += metric[client * point_count + n + kind]
        if any(loads[kind] > multiplicity[kind] * capacities[kind]
               for kind in range(facility_count)):
            continue
        if best_cost is None or (service, types) < (best_cost, best_types):
            best_cost, best_types = service, types
    assert best_cost is not None and best_types is not None

    assignment = [-1] * n
    copy_loads = [0] * len(copy_types)
    for client, kind in enumerate(best_types):
        for copy, copy_kind in enumerate(copy_types):
            if copy_kind == kind and copy_loads[copy] < capacities[kind]:
                assignment[client] = copy
                copy_loads[copy] += 1
                break
    total = sum(fees[kind] for kind in copy_types) + best_cost
    return total, assignment, list(copy_types)


def _t_hunt_subset(n: int, facility_count: int, metric: list[int], fees: list[int],
                   capacities: list[int], copy_types: list[int], assignment: list[int],
                   target: int, copies_added: int) -> tuple[int, list[int]]:
    """Exact-weight DP; equal states retain the path that skips the latest copy."""
    point_count = n + facility_count
    copy_count = len(copy_types)
    loads = [0] * copy_count
    profits = [fees[kind] for kind in copy_types]
    for client, copy in enumerate(assignment):
        loads[copy] += 1
        old_type = copy_types[copy]
        profits[copy] -= (
            metric[client * point_count + n + target]
            - metric[client * point_count + n + old_type]
        )

    limit = min(n, copies_added * capacities[target])
    dp: list[int | None] = [None] * (limit + 1)
    dp[0] = 0
    take_rows: list[list[bool]] = []
    for copy in range(copy_count):
        next_dp = dp.copy()
        take = [False] * (limit + 1)
        for used, value in enumerate(dp):
            new_used = used + loads[copy]
            if value is None or new_used > limit:
                continue
            candidate = value + profits[copy]
            if next_dp[new_used] is None or candidate > next_dp[new_used]:
                next_dp[new_used] = candidate
                take[new_used] = True
        dp = next_dp
        take_rows.append(take)

    best_profit: int | None = None
    best_weight = 0
    for used, value in enumerate(dp):
        if value is not None and (best_profit is None or value > best_profit):
            best_profit, best_weight = value, used
    assert best_profit is not None
    selected: list[int] = []
    used = best_weight
    for copy in range(copy_count - 1, -1, -1):
        if take_rows[copy][used]:
            selected.append(copy)
            used -= loads[copy]
    selected.reverse()
    return best_profit, selected


def _solve(n: int, facility_count: int, metric: list[int], fees: list[int],
           capacities: list[int], initial_types: list[int]
           ) -> tuple[int, int, list[int], list[int]]:
    current_cost, assignment, copy_types = _canonical_assignment(
        n, facility_count, metric, fees, capacities, initial_types
    )
    accepted_steps = 0
    while accepted_steps < MAX_ACCEPTED_STEPS:
        moved = False
        for target in range(facility_count):
            # The source neighborhood separately permits adding a single copy.
            added_types = sorted(copy_types + [target])
            added_cost, added_assignment, added_types = _canonical_assignment(
                n, facility_count, metric, fees, capacities, added_types
            )
            if added_cost < current_cost:
                current_cost, assignment, copy_types = (
                    added_cost, added_assignment, added_types
                )
                accepted_steps += 1
                moved = True
                break

            # Figure 13's T-Hunt scans l increasingly and accepts its first gain.
            for copies_added in range(1, n + 1):
                profit, selected = _t_hunt_subset(
                    n, facility_count, metric, fees, capacities, copy_types,
                    assignment, target, copies_added
                )
                if profit <= copies_added * fees[target]:
                    continue
                selected_set = set(selected)
                candidate_types = [kind for copy, kind in enumerate(copy_types)
                                   if copy not in selected_set]
                candidate_types.extend([target] * copies_added)
                candidate_types.sort()
                candidate_cost, candidate_assignment, candidate_types = _canonical_assignment(
                    n, facility_count, metric, fees, capacities, candidate_types
                )
                if candidate_cost < current_cost:
                    current_cost, assignment, copy_types = (
                        candidate_cost, candidate_assignment, candidate_types
                    )
                    accepted_steps += 1
                    moved = True
                    break
            if moved:
                break
        if not moved:
            break
    return current_cost, accepted_steps, copy_types, assignment


def expected_output(values: Sequence[int] | None, *, capacity: int | None = None,
                    input_length: int | None = None, input_is_null: bool = False,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    n, facility_count, metric, fees, capacities, initial_types = decoded
    cost, steps, copy_types, assignment = _solve(
        n, facility_count, metric, fees, capacities, initial_types
    )
    words = [cost, steps, len(copy_types), *copy_types, *assignment]
    needed = 8 * len(words)
    if output_is_null or (
            capacity is not None and (type(capacity) is not int or capacity < needed)):
        return -2, b""
    return needed, struct.pack("<" + "q" * len(words), *words)

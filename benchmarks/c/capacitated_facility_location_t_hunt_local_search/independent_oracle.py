"""Independent reference using weight-class enumeration for each T-Hunt call."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

from .primary_oracle import (
    MAX_ACCEPTED_STEPS,
    MAX_CLIENTS,
    MAX_DISTANCE,
    MAX_FACILITY_TYPES,
    MAX_INITIAL_COPIES,
    MAX_OPENING_FEE,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))):
        return None
    if (len(values) < 10 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63)
                   for v in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, f, initial_count = values[:3]
    if not (1 <= n <= MAX_CLIENTS and 1 <= f <= MAX_FACILITY_TYPES
            and 1 <= initial_count <= MAX_INITIAL_COPIES):
        return None
    p = n + f
    if len(values) != 3 + p * p + 2 * f + initial_count:
        return None
    at = 3
    metric = list(values[at:at + p * p]); at += p * p
    if any(x < 0 or x > MAX_DISTANCE for x in metric):
        return None
    for a in range(p):
        if metric[a * p + a] != 0:
            return None
        for b in range(p):
            ab = metric[a * p + b]
            if a != b and ab == 0:
                return None
            if ab != metric[b * p + a]:
                return None
            for c in range(p):
                if ab > metric[a * p + c] + metric[c * p + b]:
                    return None
    fee = list(values[at:at + f]); at += f
    capacity = list(values[at:at + f]); at += f
    copies = list(values[at:])
    if any(x < 0 or x > MAX_OPENING_FEE for x in fee):
        return None
    if any(x < 1 or x > n for x in capacity):
        return None
    if any(x < 0 or x >= f for x in copies):
        return None
    if sum(capacity[k] for k in copies) < n:
        return None
    return n, f, metric, fee, capacity, sorted(copies)


def _minimum_assignment(n: int, f: int, metric: list[int], fee: list[int],
                        capacity: list[int], copies: list[int]):
    p = n + f
    multiplicity = [copies.count(k) for k in range(f)]
    choices = []
    for assignment_types in itertools.product(range(f), repeat=n):
        counts = [assignment_types.count(k) for k in range(f)]
        if any(counts[k] > multiplicity[k] * capacity[k] for k in range(f)):
            continue
        service = sum(metric[j * p + n + assignment_types[j]] for j in range(n))
        choices.append((service, assignment_types))
    service, chosen_types = min(choices)
    copy_loads = [0] * len(copies)
    assignment = []
    for kind in chosen_types:
        for copy, copy_kind in enumerate(copies):
            if copy_kind == kind and copy_loads[copy] < capacity[kind]:
                copy_loads[copy] += 1
                assignment.append(copy)
                break
    total = service + sum(fee[kind] for kind in copies)
    return total, assignment, copies[:]


def _enumerated_knapsack(n: int, f: int, metric: list[int], fee: list[int],
                         capacity: list[int], copies: list[int], assignment: list[int],
                         target: int, l: int):
    """Enumerate feasible class counts instead of building a capacity DP."""
    p = n + f
    loads = [0] * len(copies)
    profits = [fee[kind] for kind in copies]
    for client, copy in enumerate(assignment):
        loads[copy] += 1
        profits[copy] += (
            metric[client * p + n + copies[copy]]
            - metric[client * p + n + target]
        )
    limit = min(n, l * capacity[target])
    groups: list[list[tuple[int, int]]] = [[] for _ in range(n + 1)]
    for copy, weight in enumerate(loads):
        groups[weight].append((copy, profits[copy]))

    zero_selected = [copy for copy, value in groups[0] if value > 0]
    base_profit = sum(profits[copy] for copy in zero_selected)
    base_mask = sum(1 << copy for copy in zero_selected)
    options: list[list[tuple[int, int, int, list[int]]]] = []
    for weight in range(1, n + 1):
        ordered = sorted(groups[weight], key=lambda item: (-item[1], item[0]))
        prefix_profit = 0
        prefix_ids: list[int] = []
        weight_options = [(0, 0, 0, [])]
        for amount, (copy, value) in enumerate(ordered, start=1):
            prefix_profit += value
            prefix_ids.append(copy)
            if amount * weight <= limit:
                mask = sum(1 << index for index in prefix_ids)
                weight_options.append((amount * weight, prefix_profit, mask, prefix_ids[:]))
        options.append(weight_options)

    # Since n<=4, the Cartesian product has at most 60 positive-weight cases.
    best_profit = base_profit
    best_weight = 0
    best_mask = base_mask
    for combination in itertools.product(*options):
        total_weight = sum(item[0] for item in combination)
        if total_weight > limit:
            continue
        profit = base_profit + sum(item[1] for item in combination)
        mask = base_mask | sum(item[2] for item in combination)
        if (profit > best_profit
                or (profit == best_profit and total_weight < best_weight)
                or (profit == best_profit and total_weight == best_weight and mask < best_mask)):
            best_profit, best_weight, best_mask = profit, total_weight, mask
    selected = [copy for copy in range(len(copies)) if best_mask & (1 << copy)]
    return best_profit, selected


def _solve(n: int, f: int, metric: list[int], fee: list[int], capacity: list[int],
           initial_copies: list[int]):
    cost, assignment, copies = _minimum_assignment(
        n, f, metric, fee, capacity, initial_copies
    )
    steps = 0
    while steps < MAX_ACCEPTED_STEPS:
        changed = False
        for target in range(f):
            candidate = sorted(copies + [target])
            new_cost, new_assignment, candidate = _minimum_assignment(
                n, f, metric, fee, capacity, candidate
            )
            if new_cost < cost:
                cost, assignment, copies = new_cost, new_assignment, candidate
                steps += 1
                changed = True
                break
            for l in range(1, n + 1):
                profit, selected = _enumerated_knapsack(
                    n, f, metric, fee, capacity, copies, assignment, target, l
                )
                if profit <= l * fee[target]:
                    continue
                selected_set = set(selected)
                candidate = [kind for i, kind in enumerate(copies) if i not in selected_set]
                candidate.extend([target] * l)
                candidate.sort()
                new_cost, new_assignment, candidate = _minimum_assignment(
                    n, f, metric, fee, capacity, candidate
                )
                if new_cost < cost:
                    cost, assignment, copies = new_cost, new_assignment, candidate
                    steps += 1
                    changed = True
                    break
            if changed:
                break
        if not changed:
            break
    return cost, steps, copies, assignment


def expected_output(values: Sequence[int] | None, *, capacity: int | None = None,
                    input_length: int | None = None, input_is_null: bool = False,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    n, f, metric, fee, copy_capacity, copies = parsed
    cost, steps, copies, assignment = _solve(
        n, f, metric, fee, copy_capacity, copies
    )
    words = [cost, steps, len(copies), *copies, *assignment]
    needed = 8 * len(words)
    if output_is_null or (
            capacity is not None and (type(capacity) is not int or capacity < needed)):
        return -2, b""
    return needed, struct.pack("<" + "q" * len(words), *words)

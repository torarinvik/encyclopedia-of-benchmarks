"""Primary exhaustive oracle for one bounded robust-scheduling transition."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_MACHINES = 3
MAX_OLD_JOBS = 8
MAX_INPUT = 20
MAX_OUTPUT_BYTES = 88


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 6 <= len(values) <= MAX_INPUT
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    machines, old_count, claimed_opt, new_size = values[:4]
    if not 2 <= machines <= MAX_MACHINES or not 1 <= old_count <= MAX_OLD_JOBS:
        return None
    if claimed_opt < 1 or not 1 <= new_size <= 20 or len(values) != 4 + 2 * old_count:
        return None
    sizes, assignment = [], []
    for i in range(old_count):
        size, machine = values[4 + 2 * i:6 + 2 * i]
        if not 1 <= size <= 20 or not 0 <= machine < machines:
            return None
        sizes.append(size)
        assignment.append(machine)
    return machines, claimed_opt, new_size, sizes, assignment


def _exact_optimum(machines: int, sizes: list[int]) -> int:
    best = sum(sizes)
    assignment_count = machines ** len(sizes)
    for code in range(assignment_count):
        loads = [0] * machines
        remaining = code
        for size in sizes:
            target = remaining % machines
            remaining //= machines
            loads[target] += size
        makespan = max(loads)
        if makespan < best:
            best = makespan
    return best


def _transition(decoded):
    machines, claimed_opt, new_size, old_sizes, old_assignment = decoded
    all_sizes = old_sizes + [new_size]
    optimum = _exact_optimum(machines, all_sizes)
    if claimed_opt != optimum:
        return None
    assignment = old_assignment + [-1]
    loads = [0] * machines
    for size, machine in zip(old_sizes, old_assignment):
        loads[machine] += size
    moved_volume = 0
    if 2 * new_size <= optimum:
        target = min(range(machines), key=lambda machine: (loads[machine], machine))
        assignment[-1] = target
        loads[target] += new_size
    else:
        source = None
        for machine in range(machines):
            contents = [i for i, assigned in enumerate(old_assignment) if assigned == machine]
            if (all(2 * old_sizes[i] <= optimum for i in contents)
                    and sum(old_sizes[i] for i in contents) >= new_size):
                source = machine
                break
        if source is None:
            return None
        removed = []
        removed_total = 0
        for i, assigned in enumerate(old_assignment):
            if assigned == source:
                removed.append(i)
                removed_total += old_sizes[i]
                if removed_total >= new_size:
                    break
        if removed_total < new_size:
            return None
        assignment[-1] = source
        loads[source] += new_size - removed_total
        for i in removed:
            target = min(range(machines), key=lambda machine: (loads[machine], machine))
            assignment[i] = target
            loads[target] += old_sizes[i]
            if target != source:
                moved_volume += old_sizes[i]
    return [optimum, moved_volume, *assignment]


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
    fields = _transition(decoded)
    if fields is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

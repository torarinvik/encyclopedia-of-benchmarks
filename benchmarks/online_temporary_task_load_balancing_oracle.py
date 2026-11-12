"""Expiration-heap oracle for online temporary-task load assignment."""

from __future__ import annotations

import heapq
from collections.abc import Sequence

MAX_MACHINES = 8
MAX_TASKS = 32
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_TASKS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_TASKS + 1)
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    machine_count, task_count = values[:2]
    if not 1 <= machine_count <= MAX_MACHINES or not 0 <= task_count <= MAX_TASKS:
        return None
    if input_length != 2 + 3 * task_count:
        return None
    tasks: list[tuple[int, int, int]] = []
    previous_arrival = -1
    for index in range(task_count):
        arrival, weight, duration = values[2 + 3 * index:5 + 3 * index]
        if not 0 <= arrival <= 1000 or arrival < previous_arrival:
            return None
        if not 1 <= weight <= 1000 or not 1 <= duration <= 1000:
            return None
        if arrival + duration > 2000:
            return None
        previous_arrival = arrival
        tasks.append((arrival, weight, duration))
    return machine_count, tasks


def _run_heap(machine_count: int,
              tasks: list[tuple[int, int, int]]) -> list[int]:
    loads = [0] * machine_count
    assignments: list[int] = []
    # (completion time, task index); task order resolves equal heap keys.
    expirations: list[tuple[int, int]] = []
    peak = 0
    for task_index, (arrival, weight, duration) in enumerate(tasks):
        while expirations and expirations[0][0] <= arrival:
            _, expired_index = heapq.heappop(expirations)
            expired_weight = tasks[expired_index][1]
            loads[assignments[expired_index]] -= expired_weight

        machine = 0
        for candidate in range(1, machine_count):
            if loads[candidate] < loads[machine]:
                machine = candidate
        assignments.append(machine)
        loads[machine] += weight
        peak = max(peak, loads[machine])
        heapq.heappush(expirations, (arrival + duration, task_index))
    return [peak, *assignments]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    machine_count, tasks = parsed
    words = _run_heap(machine_count, tasks)
    encoded = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return CAPACITY_ERROR, b""
    if output_is_null or effective_capacity < len(encoded):
        return CAPACITY_ERROR, b""
    return len(encoded), encoded


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]

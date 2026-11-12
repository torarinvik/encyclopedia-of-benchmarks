"""Independent history-replay oracle for temporary-task load assignment."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MACHINES = 8
MAX_TASKS = 32
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_TASKS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_TASKS + 1)
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _valid_tasks(values: Sequence[int] | None, input_is_null: bool,
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
    machine_count, task_count = values[0], values[1]
    if not 1 <= machine_count <= MAX_MACHINES or not 0 <= task_count <= MAX_TASKS:
        return None
    if len(values) != 2 + 3 * task_count:
        return None
    tasks: list[tuple[int, int, int]] = []
    last_arrival = -1
    for i in range(task_count):
        arrival = values[2 + 3 * i]
        weight = values[3 + 3 * i]
        duration = values[4 + 3 * i]
        if not 0 <= arrival <= 1000 or arrival < last_arrival:
            return None
        if not 1 <= weight <= 1000 or not 1 <= duration <= 1000:
            return None
        if arrival + duration > 2000:
            return None
        last_arrival = arrival
        tasks.append((arrival, weight, duration))
    return machine_count, tasks


def _replay_history(machine_count: int,
                    tasks: list[tuple[int, int, int]]) -> list[int]:
    assignments: list[int] = []
    peak = 0
    for current_index, (arrival, weight, duration) in enumerate(tasks):
        # Recompute each current machine load from all earlier assignments.
        active_loads = [0] * machine_count
        for prior_index in range(current_index):
            prior_arrival, prior_weight, prior_duration = tasks[prior_index]
            if prior_arrival + prior_duration > arrival:
                active_loads[assignments[prior_index]] += prior_weight

        machine = 0
        for candidate in range(1, machine_count):
            if active_loads[candidate] < active_loads[machine]:
                machine = candidate
        assignments.append(machine)
        active_loads[machine] += weight
        if max(active_loads) > peak:
            peak = max(active_loads)
    return [peak, *assignments]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _valid_tasks(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    machine_count, tasks = parsed
    words = _replay_history(machine_count, tasks)
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

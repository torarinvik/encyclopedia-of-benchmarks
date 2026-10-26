"""Critical-instant simulation oracle for a bounded RM task system."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TASKS = 8
MAX_INPUT = 1 + 2 * MAX_TASKS
MAX_OUTPUT_BYTES = 8 * (MAX_TASKS + 2)


def _parse(values: Sequence[int] | None) -> list[tuple[int, int]] | None:
    if not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_INPUT:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_TASKS or len(values) != 1 + 2 * count:
        return None
    tasks = []
    for task in range(count):
        execution, period = values[1 + 2 * task:3 + 2 * task]
        if not 1 <= execution <= 16 or not 1 <= period <= 32:
            return None
        tasks.append((execution, period))
    return tasks


def _critical_responses(tasks: list[tuple[int, int]]) -> tuple[int, int, list[int]]:
    order = sorted(range(len(tasks)), key=lambda task: (tasks[task][1], task))
    responses = [-1] * len(tasks)
    for rank, target in enumerate(order):
        execution, deadline = tasks[target]
        higher = order[:rank]
        active = [0] * len(tasks)
        remaining_target = execution
        elapsed = 0
        while remaining_target > 0 and elapsed < deadline:
            for task in higher:
                if elapsed % tasks[task][1] == 0:
                    active[task] += tasks[task][0]
            selected = -1
            for task in higher:
                if active[task] > 0:
                    selected = task
                    break
            if selected >= 0:
                active[selected] -= 1
            else:
                remaining_target -= 1
            elapsed += 1
        if remaining_target > 0:
            return 0, target, responses
        responses[target] = elapsed
    return 1, -1, responses


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
    tasks = _parse(values)
    if tasks is None:
        return -1, b""
    status, failed_task, responses = _critical_responses(tasks)
    fields = [status, failed_task, *responses]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

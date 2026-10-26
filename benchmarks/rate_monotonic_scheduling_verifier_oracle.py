"""Independent fixed-point response-time verifier for RM schedulability."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TASKS = 8
MAX_INPUT = 1 + 2 * MAX_TASKS


def _valid_tasks(values: Sequence[int] | None) -> list[tuple[int, int]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_TASKS or len(values) != 1 + 2 * n:
        return None
    tasks = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]
    if any(not 1 <= execution <= 16 or not 1 <= period <= 32
           for execution, period in tasks):
        return None
    return tasks


def _fixed_point_responses(tasks: list[tuple[int, int]]) -> tuple[int, int, list[int]]:
    order = sorted(range(len(tasks)), key=lambda task: (tasks[task][1], task))
    responses = [-1] * len(tasks)
    for rank, target in enumerate(order):
        execution, deadline = tasks[target]
        response = execution
        while response <= deadline:
            next_response = execution
            for higher in order[:rank]:
                higher_execution, higher_period = tasks[higher]
                jobs = (response + higher_period - 1) // higher_period
                next_response += jobs * higher_execution
            if next_response == response:
                responses[target] = response
                break
            if next_response > deadline:
                return 0, target, responses
            response = next_response
        if responses[target] < 0:
            return 0, target, responses
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
    tasks = _valid_tasks(values)
    if tasks is None:
        return -1, b""
    status, failed_task, responses = _fixed_point_responses(tasks)
    payload = b"".join(struct.pack("<q", field)
                       for field in [status, failed_task, *responses])
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

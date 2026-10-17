"""Oracle for the bounded Java SelfAdjustingScheduling operation trace."""

from __future__ import annotations

from collections.abc import Sequence


MAX_TASKS = 16
MAX_STEPS = 64
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = MAX_TASKS + 2
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_STEPS
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _valid_array(values: object) -> bool:
    return (
        isinstance(values, (list, tuple))
        and 2 <= len(values) <= MAX_INPUT_LENGTH
        and all(type(value) is int and I64_MIN <= value <= I64_MAX
                for value in values)
    )


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the byte trace after validating the entire bounded schedule."""
    if not _valid_array(values):
        return INVALID_RESULT, b""

    task_count, steps = values[0], values[1]
    if (not 1 <= task_count <= MAX_TASKS
            or not 0 <= steps <= MAX_STEPS
            or len(values) != task_count + 2):
        return INVALID_RESULT, b""

    priorities = list(values[2:])
    if any(not I32_MIN <= priority <= I32_MAX for priority in priorities):
        return INVALID_RESULT, b""

    wait_times = [0] * task_count
    schedule = bytearray()
    for _ in range(steps):
        # The pinned Java comparator compares priority only. Ties are excluded
        # before each poll so the selected task is deterministic.
        if len(set(priorities)) != task_count:
            return INVALID_RESULT, b""
        selected = min(range(task_count), key=priorities.__getitem__)
        schedule.append(selected)
        wait_times[selected] += 1
        updated_priority = priorities[selected] + wait_times[selected]
        if not I32_MIN <= updated_priority <= I32_MAX:
            return INVALID_RESULT, b""
        priorities[selected] = updated_priority

    output = bytes(schedule)
    if (type(output_is_null) is not bool
            or (capacity is not None
                and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and len(output) > capacity):
        return OUTPUT_ERROR, b""
    return len(output), output

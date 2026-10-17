"""Oracle for the bounded Java/Rust greedy job-sequencing contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_JOBS = 32
MAX_PROFIT = 1_000_000
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_JOBS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return result length and the packed schedule bytes."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    job_count = values[0]
    if not 1 <= job_count <= MAX_JOBS or len(values) != 1 + 3 * job_count:
        return INVALID_RESULT, b""
    seen_ids: set[int] = set()
    jobs: list[tuple[int, int, int]] = []
    previous_profit = MAX_PROFIT + 1
    for offset in range(1, len(values), 3):
        ident, deadline, profit = values[offset:offset + 3]
        if not (65 <= ident <= 90 or 97 <= ident <= 122) or ident in seen_ids:
            return INVALID_RESULT, b""
        if not 1 <= deadline <= job_count or not 1 <= profit <= MAX_PROFIT or profit >= previous_profit:
            return INVALID_RESULT, b""
        seen_ids.add(ident)
        previous_profit = profit
        jobs.append((ident, deadline, profit))

    slots = [0] * job_count
    total_profit = 0
    for ident, deadline, profit in jobs:
        for slot in range(min(deadline, job_count) - 1, -1, -1):
            if slots[slot] == 0:
                slots[slot] = ident
                total_profit += profit
                break
    scheduled = [ident for ident in slots if ident != 0]
    output = bytes([len(scheduled)]) + total_profit.to_bytes(8, "little") + bytes(scheduled)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    return len(output), output

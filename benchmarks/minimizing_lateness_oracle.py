"""Independent bounded oracle for stable earliest-deadline-first scheduling."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_JOBS = 64
MAX_INPUT_VALUES = 1 + 2 * MAX_JOBS
MAX_OUTPUT_BYTES = 4 + 12 * MAX_JOBS
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_VALUES
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    count = values[0]
    if not 0 <= count <= MAX_JOBS or len(values) != 1 + 2 * count:
        return INVALID_RESULT, b""

    jobs: list[tuple[int, int, int]] = []
    total_processing = 0
    for index in range(count):
        processing, deadline = values[1 + 2 * index:3 + 2 * index]
        if not 0 <= processing <= I32_MAX or not 0 <= deadline <= I32_MAX:
            return INVALID_RESULT, b""
        total_processing += processing
        if total_processing > I32_MAX:
            return INVALID_RESULT, b""
        jobs.append((deadline, index, processing))

    # Python's sort is stable, matching Arrays.sort on the pinned object array.
    jobs.sort(key=lambda job: job[0])
    records: list[int] = [count]
    start_time = 0
    for deadline, original_index, processing in jobs:
        finish_time = start_time + processing
        lateness = max(0, finish_time - deadline)
        records.extend((original_index, start_time, lateness))
        start_time = finish_time

    output = b"".join(struct.pack("<i", value) for value in records)
    if output_is_null or (capacity is not None and (type(capacity) is not int or capacity < len(output))):
        return CAPACITY_ERROR, b""
    return len(output), output


def expected_result(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    return expected_output(values, capacity, output_is_null)

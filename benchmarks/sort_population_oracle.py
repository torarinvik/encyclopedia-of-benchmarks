"""Independent oracle for bounded ascending population ordering by cost."""

from __future__ import annotations

import struct
from typing import Sequence


MIN_RECORDS = 1
MAX_RECORDS = 64
MIN_COST = -1_000_000
MAX_COST = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_RECORDS
MAX_OUTPUT_BYTES = 16 * MAX_RECORDS
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Validate records and return `(status, sorted little-endian record bytes)`."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    count = values[0]
    if not MIN_RECORDS <= count <= MAX_RECORDS or len(values) != 1 + 2 * count:
        return INVALID_RESULT, b""

    records: list[tuple[int, int]] = []
    for offset in range(count):
        cost = values[1 + 2 * offset]
        identifier = values[2 + 2 * offset]
        if not MIN_COST <= cost <= MAX_COST:
            return INVALID_RESULT, b""
        records.append((cost, identifier))

    costs = [cost for cost, _ in records]
    identifiers = [identifier for _, identifier in records]
    if (len(set(costs)) != count
            or sorted(identifiers) != list(range(count))):
        return INVALID_RESULT, b""

    records.sort(key=lambda record: record[0])
    output = b"".join(struct.pack("<qq", cost, identifier)
                      for cost, identifier in records)
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and len(output) > capacity):
        return OUTPUT_ERROR, b""
    return len(output), output

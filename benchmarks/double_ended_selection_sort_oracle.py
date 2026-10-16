"""Oracle for the pinned Python double_ended_selection_sort double-ended extraction loop."""
from __future__ import annotations

MAX_INPUT_LENGTH = 256
MAX_PARSEABLE_LENGTH = 257
MAX_OUTPUT_BYTES = 8 * MAX_INPUT_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > MAX_PARSEABLE_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return -1, b""
    if len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    remaining = values.copy()
    start: list[int] = []
    end: list[int] = []
    while len(remaining) > 1:
        minimum = min(remaining)
        maximum = max(remaining)
        start.append(minimum)
        end.append(maximum)
        remaining.remove(minimum)
        remaining.remove(maximum)
    result = start + remaining + end[::-1]
    output = b"".join(value.to_bytes(8, "little", signed=True) for value in result)
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output

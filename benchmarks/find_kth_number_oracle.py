"""Independent sorting oracle for the bounded Java max-heap selection port."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_VALUES = 1024
MAX_INPUT_LENGTH = MAX_VALUES + 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return I64_MIN
    rank, data = values[0], values[1:]
    if (not 1 <= len(data) <= MAX_VALUES or not 1 <= rank <= len(data)
            or any(not I32_MIN <= value <= I32_MAX for value in data)):
        return I64_MIN
    return sorted(data, reverse=True)[rank - 1]

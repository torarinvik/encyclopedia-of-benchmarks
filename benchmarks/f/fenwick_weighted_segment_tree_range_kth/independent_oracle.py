"""Direct update-and-sort reference, independent of the Fenwick value trees."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import (
        I64_MAX, I64_MIN, MAX_N, MAX_Q, MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALUE, MIN_VALUE,
    )
except ImportError:
    from primary_oracle import (
        I64_MAX, I64_MIN, MAX_N, MAX_Q, MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALUE, MIN_VALUE,
    )


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return I64_MIN
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return I64_MIN
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 4 * q:
        return I64_MIN
    current = list(values[2:2 + n])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in current):
        return I64_MIN
    cursor = 2 + n
    operations: list[tuple[int, int, int, int]] = []
    for _ in range(q):
        opcode, first, second, third = values[cursor:cursor + 4]
        cursor += 4
        if opcode == 0:
            if not 0 <= first < n or not MIN_VALUE <= second <= MAX_VALUE or third != 0:
                return I64_MIN
            current[first] = second
        elif opcode == 1:
            if not 0 <= first < second <= n or not 1 <= third <= second - first:
                return I64_MIN
        else:
            return I64_MIN
        operations.append((opcode, first, second, third))

    current = list(values[2:2 + n])
    result = 0
    query_ordinal = 0
    for opcode, first, second, third in operations:
        if opcode == 0:
            current[first] = second
        else:
            selected = sorted(current[first:second])[third - 1]
            query_ordinal += 1
            result += query_ordinal * selected
    return result

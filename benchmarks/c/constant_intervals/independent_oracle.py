"""Independent threshold-equation and direct-scan references."""

from __future__ import annotations

from c.constant_intervals.primary_oracle import _parameters, encode


def value_at(index: int, step: int, offset: int, divisor: int) -> int:
    return (step * index + offset) // divisor


def intervals_by_threshold(n: int, step: int, offset: int, divisor: int) -> list[tuple[int, int, int]]:
    """Find each next run end from the quotient's exact upper threshold."""
    result: list[tuple[int, int, int]] = []
    lo = 0
    while lo < n:
        value = value_at(lo, step, offset, divisor)
        if step == 0:
            hi = n
        else:
            threshold = (value + 1) * divisor - offset
            hi = (threshold + step - 1) // step
            hi = min(n, max(lo + 1, hi))
        result.append((lo, hi, value))
        lo = hi
    return result


def intervals_by_scan(n: int, step: int, offset: int, divisor: int) -> list[tuple[int, int, int]]:
    """Group values obtained by visiting every index in order."""
    result: list[tuple[int, int, int]] = []
    if n == 0:
        return result
    start = 0
    previous = value_at(0, step, offset, divisor)
    for index in range(1, n):
        current = value_at(index, step, offset, divisor)
        if current != previous:
            result.append((start, index, previous))
            start, previous = index, current
    result.append((start, n, previous))
    return result


def expected_call(values: list[int] | tuple[int, ...] | None,
                  capacity: int | None = None,
                  output_is_null: bool = False,
                  input_is_null: bool = False,
                  input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    parameters = _parameters(values, input_is_null, input_length)
    if parameters is None:
        return -1, b""
    n, step, offset, divisor = parameters
    if ((n > 0 and output_is_null)
            or (capacity is not None and capacity < n * 12)):
        return -2, b""
    records = intervals_by_threshold(n, step, offset, divisor)
    return len(records), encode(records)

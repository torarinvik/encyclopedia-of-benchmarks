"""Tick-by-tick reference for the virtual-time token bucket."""

from __future__ import annotations

from collections.abc import Callable, Sequence

MAX_CAPACITY = 64
MAX_REFILL_RATE = 32
MAX_REQUESTS = 63
MAX_ELAPSED_TICKS = 256


def _read(values: Sequence[int] | None, input_is_null: bool = False,
          input_length: int | None = None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values) or size < 3 or size > 66:
        return None
    capacity, rate, count = values[:3]
    if not 0 <= capacity <= MAX_CAPACITY or not 0 <= rate <= MAX_REFILL_RATE:
        return None
    if not 0 <= count <= MAX_REQUESTS or size != count + 3:
        return None
    intervals = values[3:]
    if len(intervals) != count or any(not 0 <= delay <= MAX_ELAPSED_TICKS for delay in intervals):
        return None
    return capacity, rate, intervals


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return -1
    capacity, rate, intervals = parsed
    balance = capacity
    flags = 0
    for request_index, interval in enumerate(intervals):
        for _ in range(interval):
            if balance < capacity:
                balance = min(capacity, balance + rate)
        if balance != 0:
            flags |= 1 << request_index
            balance -= 1
    return flags


def verify_candidate(candidate: Callable[..., int], values: Sequence[int],
                     expected: int | None = None) -> bool:
    if expected is None:
        expected = expected_result(values)
    return candidate(values, len(values)) == expected

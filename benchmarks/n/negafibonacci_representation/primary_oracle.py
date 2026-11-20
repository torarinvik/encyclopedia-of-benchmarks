"""Interval-recurrence reference for bounded NegaFibonacci encoding."""

from __future__ import annotations

from typing import Optional

MAX_INDEX = 17
VALUE_LIMIT = 1000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 1
MAX_OUTPUT_BYTES = MAX_INDEX
MAX_WORKSPACE_BYTES = 640


def _weights() -> list[int]:
    fib = [0] * (MAX_INDEX + 1)
    fib[1] = 1
    fib[2] = 1
    for index in range(3, MAX_INDEX + 1):
        fib[index] = fib[index - 1] + fib[index - 2]
    return [0] + [fib[index] if index & 1 else -fib[index]
                  for index in range(1, MAX_INDEX + 1)]


WEIGHTS = _weights()


def _intervals() -> tuple[list[int], list[int]]:
    low = [0] * (MAX_INDEX + 1)
    high = [0] * (MAX_INDEX + 1)
    for index in range(1, MAX_INDEX + 1):
        lower_suffix_low = 0 if index == 1 else low[index - 2]
        lower_suffix_high = 0 if index == 1 else high[index - 2]
        with_top_low = WEIGHTS[index] + lower_suffix_low
        with_top_high = WEIGHTS[index] + lower_suffix_high
        low[index] = min(low[index - 1], with_top_low)
        high[index] = max(high[index - 1], with_top_high)
    return low, high


LOW, HIGH = _intervals()


def _valid(values: list[int]) -> bool:
    return len(values) == 1 and -VALUE_LIMIT <= values[0] <= VALUE_LIMIT


def encode(value: int) -> bytes:
    if not (-VALUE_LIMIT <= value <= VALUE_LIMIT):
        raise ValueError("value outside the bounded NegaFibonacci profile")
    if not (LOW[MAX_INDEX] <= value <= HIGH[MAX_INDEX]):
        raise ValueError("value outside the representable interval")
    remaining = value
    selected_above = False
    digits = [0] * (MAX_INDEX + 1)
    for index in range(MAX_INDEX, 0, -1):
        choose = False
        if not selected_above:
            suffix_low = 0 if index == 1 else LOW[index - 2]
            suffix_high = 0 if index == 1 else HIGH[index - 2]
            candidate = remaining - WEIGHTS[index]
            choose = suffix_low <= candidate <= suffix_high
        if choose:
            digits[index] = 1
            remaining -= WEIGHTS[index]
        elif not (LOW[index - 1] <= remaining <= HIGH[index - 1]):
            raise AssertionError("interval selection lost a representable remainder")
        selected_above = choose
    if remaining != 0:
        raise AssertionError("interval selection did not consume the input")
    highest = MAX_INDEX
    while highest > 1 and digits[highest] == 0:
        highest -= 1
    return bytes(49 if digits[index] else 48 for index in range(highest, 0, -1))


def expected_call(values: list[int], capacity: Optional[int] = None) -> tuple[int, bytes]:
    if not _valid(values):
        return -1, b""
    output = encode(values[0])
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output


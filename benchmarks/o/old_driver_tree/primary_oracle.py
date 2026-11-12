"""Ordered maximal-run interval-map reference for Old Driver Tree traces."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 32
MAX_Q = 32
MAX_INPUT = 195
MAX_OUTPUT_BYTES = 256
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def parse_input(values: Sequence[int] | None, input_is_null: bool = False,
                input_length: int | None = None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) < 2 + n:
        return None
    initial = list(values[2 : 2 + n])
    if any(not -1000 <= value <= 1000 for value in initial):
        return None
    cursor = 2 + n
    operations: list[tuple[int, ...]] = []
    output_count = 0
    for _ in range(q):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        cursor += 1
        width = 4 if kind in (0, 1, 2) else 5 if kind == 3 else 0
        if width == 0 or len(values) - cursor < width - 1:
            return None
        record = (kind, *values[cursor : cursor + width - 1])
        cursor += width - 1
        _, left, right, argument, *extra = record
        if not 0 <= left <= right < n:
            return None
        if kind in (0, 1):
            if not -1000 <= argument <= 1000:
                return None
        elif kind == 2:
            if not 1 <= argument <= right - left + 1:
                return None
            output_count += 1
        else:
            exponent, modulus = argument, extra[0]
            if not 0 <= exponent <= 8 or not 1 <= modulus <= 1_000_000_000:
                return None
            output_count += 1
        operations.append(record)
    if cursor != len(values) or len(values) > 2 + MAX_N + 5 * MAX_Q:
        return None
    return n, initial, operations, output_count


def _lower_bound(intervals: list[tuple[int, int, int]], point: int) -> int:
    lo, hi = 0, len(intervals)
    while lo < hi:
        mid = (lo + hi) // 2
        if intervals[mid][0] < point:
            lo = mid + 1
        else:
            hi = mid
    return lo


def _split(intervals: list[tuple[int, int, int]], point: int, n: int) -> None:
    if point <= 0 or point >= n:
        return
    at = _lower_bound(intervals, point)
    if at < len(intervals) and intervals[at][0] == point:
        return
    left, right, value = intervals[at - 1]
    intervals[at - 1] = (left, point - 1, value)
    intervals.insert(at, (point, right, value))


def _coalesce(intervals: list[tuple[int, int, int]]) -> None:
    merged: list[tuple[int, int, int]] = []
    for left, right, value in intervals:
        if merged and merged[-1][1] + 1 == left and merged[-1][2] == value:
            old_left, _, old_value = merged[-1]
            merged[-1] = (old_left, right, old_value)
        else:
            merged.append((left, right, value))
    intervals[:] = merged


def _power(base: int, exponent: int, modulus: int) -> int:
    result = 1 % modulus
    value = base % modulus
    while exponent:
        if exponent & 1:
            result = result * value % modulus
        value = value * value % modulus
        exponent >>= 1
    return result


def _evaluate(initial: list[int], operations: list[tuple[int, ...]]) -> list[int]:
    intervals: list[tuple[int, int, int]] = []
    for index, value in enumerate(initial):
        if intervals and intervals[-1][2] == value:
            left, _, old = intervals[-1]
            intervals[-1] = (left, index, old)
        else:
            intervals.append((index, index, value))
    answers: list[int] = []
    n = len(initial)
    for kind, left, right, argument, *extra in operations:
        if kind in (0, 1):
            _split(intervals, right + 1, n)
            _split(intervals, left, n)
            start = _lower_bound(intervals, left)
            end = _lower_bound(intervals, right + 1)
            if kind == 0:
                intervals[start:end] = [(left, right, argument)]
            else:
                for i in range(start, end):
                    a, b, value = intervals[i]
                    intervals[i] = (a, b, value + argument)
            _coalesce(intervals)
        else:
            hits = [item for item in intervals if item[1] >= left and item[0] <= right]
            if kind == 2:
                values: list[int] = []
                for a, b, value in hits:
                    values.extend([value] * (min(b, right) - max(a, left) + 1))
                values.sort()
                answers.append(values[argument - 1])
            else:
                modulus = extra[0]
                total = 0
                for a, b, value in hits:
                    width = min(b, right) - max(a, left) + 1
                    total = (total + width * _power(value, argument, modulus)) % modulus
                answers.append(total)
    return answers


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID, b""
    parsed = parse_input(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    _, initial, operations, output_count = parsed
    required = 8 * output_count
    if required and (output_is_null or output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    answers = _evaluate(initial, operations)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload

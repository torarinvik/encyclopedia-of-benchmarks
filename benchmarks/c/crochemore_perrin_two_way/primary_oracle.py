"""Clean-room Crochemore–Perrin Two-Way matcher oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MAX_PATTERN_LENGTH = 32
MAX_INPUT_LENGTH = 99
MAX_OUTPUT_BYTES = 8 * (MAX_TEXT_LENGTH + 1)
WORKSPACE_BYTES = 4096


def _maximal_suffix(pattern: Sequence[int], reverse_order: bool) -> tuple[int, int]:
    maximal = -1
    candidate = 0
    offset = 1
    period = 1
    while candidate + offset < len(pattern):
        a = pattern[candidate + offset]
        b = pattern[maximal + offset]
        precedes = a > b if reverse_order else a < b
        if precedes:
            candidate += offset
            offset = 1
            period = candidate - maximal
        elif a == b:
            if offset != period:
                offset += 1
            else:
                candidate += period
                offset = 1
        else:
            maximal = candidate
            candidate = maximal + 1
            offset = 1
            period = 1
    return maximal, period


def _two_way(text: Sequence[int], pattern: Sequence[int]) -> list[int]:
    n = len(text)
    m = len(pattern)
    if m == 0:
        return list(range(n + 1))
    if m > n:
        return []

    first = _maximal_suffix(pattern, False)
    second = _maximal_suffix(pattern, True)
    if first[0] > second[0]:
        critical, period = first
    else:
        critical, period = second

    periodic = period + critical + 1 <= m
    if periodic:
        for i in range(critical + 1):
            if pattern[i] != pattern[i + period]:
                periodic = False
                break

    if periodic:
        memory = -1
        shift = period
    else:
        shift = max(critical, m - critical - 1) + 1
        memory = -1

    matches: list[int] = []
    start = 0
    while start <= n - m:
        index = max(critical, memory) + 1 if periodic else critical + 1
        while index < m and pattern[index] == text[start + index]:
            index += 1
        if index >= m:
            index = critical
            while index > memory and pattern[index] == text[start + index]:
                index -= 1
            if index <= memory:
                matches.append(start)
            start += shift
            memory = m - period - 1 if periodic else -1
        else:
            start += index - critical
            memory = -1
    return matches


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
        or input_is_null and values not in (None, [], ())
        or not input_is_null
        and values is not None
        and input_length is not None
        and input_length != len(values)
    ):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 0 <= pattern_length <= MAX_PATTERN_LENGTH:
        return -1, b""
    if len(values) != 2 + text_length + pattern_length:
        return -1, b""
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(not 0 <= value <= 255 for value in (*text, *pattern)):
        return -1, b""
    matches = _two_way(text, pattern)
    payload = struct.pack("<" + "q" * len(matches), *matches)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

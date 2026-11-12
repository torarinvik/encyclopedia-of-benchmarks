"""Clean-room SA-IS oracle for the bounded byte-string profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 32
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 2
MAX_OUTPUT_BYTES = 8 * MAX_TEXT_LENGTH
WORKSPACE_BYTES = 32768


def _sais(symbols: list[int], upper: int) -> list[int]:
    n = len(symbols)
    if n == 0:
        return []
    if n <= 2:
        return sorted(range(n), key=lambda start: tuple(symbols[start:]))

    is_s = [False] * n
    is_s[-1] = True
    for i in range(n - 2, -1, -1):
        is_s[i] = symbols[i] < symbols[i + 1] or (
            symbols[i] == symbols[i + 1] and is_s[i + 1]
        )

    lms = [i for i in range(1, n) if not is_s[i - 1] and is_s[i]]
    lms_map = [-1] * (n + 1)
    for rank, position in enumerate(lms):
        lms_map[position] = rank

    sum_s = [0] * (upper + 2)
    sum_l = [0] * (upper + 2)
    for i, symbol in enumerate(symbols):
        if is_s[i]:
            sum_l[symbol + 1] += 1
        else:
            sum_s[symbol] += 1
    for symbol in range(upper + 1):
        sum_s[symbol] += sum_l[symbol]
        sum_l[symbol + 1] += sum_s[symbol]

    def induce(ordered_lms: list[int]) -> list[int]:
        suffixes = [-1] * n
        bucket = sum_s.copy()
        for position in ordered_lms:
            suffixes[bucket[symbols[position]]] = position
            bucket[symbols[position]] += 1
        bucket = sum_l.copy()
        for slot in range(n):
            position = suffixes[slot]
            if position > 0 and not is_s[position - 1]:
                symbol = symbols[position - 1]
                suffixes[bucket[symbol]] = position - 1
                bucket[symbol] += 1
        bucket = sum_l.copy()
        for slot in range(n - 1, -1, -1):
            position = suffixes[slot]
            if position > 0 and is_s[position - 1]:
                symbol = symbols[position - 1] + 1
                bucket[symbol] -= 1
                suffixes[bucket[symbol]] = position - 1
        return suffixes

    suffixes = induce(lms)
    sorted_lms = [position for position in suffixes if position >= 0 and lms_map[position] >= 0]

    def same_lms_substring(left: int, right: int) -> bool:
        if left == right:
            return True
        offset = 0
        while True:
            a = left + offset
            b = right + offset
            if a >= n or b >= n or symbols[a] != symbols[b] or is_s[a] != is_s[b]:
                return False
            a_lms = offset > 0 and lms_map[a] >= 0
            b_lms = offset > 0 and lms_map[b] >= 0
            if a_lms or b_lms:
                return a_lms and b_lms
            offset += 1

    reduced = [0] * len(lms)
    reduced_upper = 0
    for i, position in enumerate(sorted_lms):
        if i > 0 and not same_lms_substring(sorted_lms[i - 1], position):
            reduced_upper += 1
        reduced[lms_map[position]] = reduced_upper

    if reduced_upper + 1 == len(reduced):
        reduced_order = [0] * len(reduced)
        for i, name in enumerate(reduced):
            reduced_order[name] = i
    else:
        reduced_order = _sais(reduced, reduced_upper)
    ordered_lms = [lms[index] for index in reduced_order]
    return induce(ordered_lms)


def _payload(values: Sequence[int]) -> bytes:
    count = values[0]
    symbols = [value + 1 for value in values[1:]] + [0]
    suffixes = _sais(symbols, 256)
    original_order = [position for position in suffixes if position != count]
    return struct.pack("<" + "q" * count, *original_order)


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
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_TEXT_LENGTH or len(values) != count + 1:
        return -1, b""
    if any(not 0 <= value <= 255 for value in values[1:]):
        return -1, b""
    payload = _payload(values)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

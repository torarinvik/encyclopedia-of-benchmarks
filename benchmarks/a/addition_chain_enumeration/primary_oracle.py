"""Iterative-deepening oracle for shortest addition-chain counts."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TARGET = 31
MAX_OUTPUT_BYTES = 24
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= 2
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= 2))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if len(values) != 1 or not 1 <= values[0] <= MAX_TARGET:
        return None
    return values[0]


def _minimum_counts(target: int) -> tuple[int, int, int]:
    if target == 1:
        return 0, 1, 0

    lower = (target - 1).bit_length()
    upper = target.bit_length() - 1 + target.bit_count() - 1
    chain = [1] * (MAX_TARGET + 1)

    def search(length: int, limit: int, all_count: list[int],
               brauer_count: list[int], prefix_is_brauer: bool) -> None:
        last = chain[length - 1]
        steps = length - 1
        if last == target:
            if steps == limit:
                all_count[0] += 1
                if prefix_is_brauer:
                    brauer_count[0] += 1
            return
        remaining = limit - steps
        if (remaining <= 0 or last * (1 << remaining) < target):
            return

        generated = bytearray(target + 1)
        for left in range(length):
            for right in range(left, length):
                candidate = chain[left] + chain[right]
                if candidate <= last or candidate > target or generated[candidate]:
                    continue
                generated[candidate] = 1
                chain[length] = candidate
                uses_last = any(last + chain[index] == candidate for index in range(length))
                search(length + 1, limit, all_count, brauer_count,
                       prefix_is_brauer and uses_last)

    for limit in range(lower, upper + 1):
        all_count = [0]
        brauer_count = [0]
        search(1, limit, all_count, brauer_count, True)
        if all_count[0]:
            return limit, brauer_count[0], all_count[0] - brauer_count[0]
    raise ValueError("binary addition chain bound failed")


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    target = _parse(values, input_is_null, input_length)
    if target is None:
        return INVALID_RESULT, b""
    result_words = _minimum_counts(target)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR_RESULT, b""
    payload = struct.pack("<qqq", *result_words)
    return len(payload), payload

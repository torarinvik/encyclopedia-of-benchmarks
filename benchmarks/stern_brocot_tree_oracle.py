"""Independent bounded oracle for batched Stern–Brocot tree queries."""
from __future__ import annotations

import math
import struct

MAX_QUERIES = 128
MAX_RUNS = 64
MAX_COMPONENT = 1_000_000_000
MAX_INPUT_LENGTH = 16_384
MAX_OUTPUT_BYTES = 262_144
INVALID_RESULT = -1


def _valid_fraction(numerator: int, denominator: int) -> bool:
    return (1 <= numerator <= MAX_COMPONENT and 1 <= denominator <= MAX_COMPONENT
            and math.gcd(numerator, denominator) == 1)


def _encode_path(numerator: int, denominator: int) -> list[tuple[int, int]]:
    runs: list[tuple[int, int]] = []
    while numerator != denominator:
        if numerator < denominator:
            count = (denominator - 1) // numerator
            denominator -= count * numerator
            direction = 0  # L
        else:
            count = (numerator - 1) // denominator
            numerator -= count * denominator
            direction = 1  # R
        if len(runs) >= MAX_RUNS:
            raise ValueError("path exceeds bounded run count")
        runs.append((direction, count))
    return runs


def _decode_path(runs: list[tuple[int, int]]) -> tuple[int, int, int, int, int, int] | None:
    lower_num, lower_den = 0, 1
    upper_num, upper_den = 1, 0
    previous_direction = -1
    for direction, count in runs:
        if direction not in (0, 1) or count < 1 or count > MAX_COMPONENT:
            return None
        if direction == previous_direction:
            return None
        if direction == 0:
            upper_num += count * lower_num
            upper_den += count * lower_den
            if upper_num > MAX_COMPONENT or upper_den > MAX_COMPONENT:
                return None
        else:
            lower_num += count * upper_num
            lower_den += count * upper_den
            if lower_num > MAX_COMPONENT or lower_den > MAX_COMPONENT:
                return None
        previous_direction = direction
    numerator = lower_num + upper_num
    denominator = lower_den + upper_den
    if not _valid_fraction(numerator, denominator):
        return None
    return numerator, denominator, lower_num, lower_den, upper_num, upper_den


def _common_prefix(left: list[tuple[int, int]], right: list[tuple[int, int]]) -> list[tuple[int, int]]:
    prefix: list[tuple[int, int]] = []
    left_index = right_index = 0
    left_used = right_used = 0
    while left_index < len(left) and right_index < len(right):
        left_direction, left_count = left[left_index]
        right_direction, right_count = right[right_index]
        if left_direction != right_direction:
            break
        shared = min(left_count - left_used, right_count - right_used)
        prefix.append((left_direction, shared))
        left_used += shared
        right_used += shared
        if left_used == left_count:
            left_index += 1
            left_used = 0
        if right_used == right_count:
            right_index += 1
            right_used = 0
    return prefix


def expected_output(values: list[int], algorithm: str = "stern_brocot_tree") -> tuple[int, bytes]:
    if (algorithm != "stern_brocot_tree" or not isinstance(values, list)
            or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    query_count = values[0]
    if not 1 <= query_count <= MAX_QUERIES:
        return INVALID_RESULT, b""
    position = 1
    words: list[int] = []
    try:
        for _ in range(query_count):
            if position >= len(values):
                return INVALID_RESULT, b""
            operation = values[position]
            position += 1
            if operation == 0:  # ENCODE_PATH
                if position + 2 > len(values):
                    return INVALID_RESULT, b""
                numerator, denominator = values[position:position + 2]
                position += 2
                if not _valid_fraction(numerator, denominator):
                    return INVALID_RESULT, b""
                runs = _encode_path(numerator, denominator)
                words.extend((operation, len(runs)))
                for direction, count in runs:
                    words.extend((direction, count))
            elif operation == 1:  # DECODE_PATH
                if position >= len(values):
                    return INVALID_RESULT, b""
                run_count = values[position]
                position += 1
                if not 0 <= run_count <= MAX_RUNS or position + 2 * run_count > len(values):
                    return INVALID_RESULT, b""
                runs = [(values[position + 2 * index], values[position + 2 * index + 1])
                        for index in range(run_count)]
                position += 2 * run_count
                decoded = _decode_path(runs)
                if decoded is None:
                    return INVALID_RESULT, b""
                words.extend((operation, decoded[0], decoded[1]))
            elif operation == 2:  # LCA
                if position + 4 > len(values):
                    return INVALID_RESULT, b""
                a, b, c, d = values[position:position + 4]
                position += 4
                if not _valid_fraction(a, b) or not _valid_fraction(c, d):
                    return INVALID_RESULT, b""
                runs = _common_prefix(_encode_path(a, b), _encode_path(c, d))
                decoded = _decode_path(runs)
                if decoded is None:
                    return INVALID_RESULT, b""
                words.extend((operation, decoded[0], decoded[1]))
            elif operation == 3:  # ANCESTOR
                if position + 3 > len(values):
                    return INVALID_RESULT, b""
                depth, numerator, denominator = values[position:position + 3]
                position += 3
                if (not 1 <= depth <= MAX_COMPONENT
                        or not _valid_fraction(numerator, denominator)):
                    return INVALID_RESULT, b""
                path = _encode_path(numerator, denominator)
                total_depth = sum(count for _, count in path)
                if depth > total_depth:
                    words.extend((operation, -1))
                else:
                    prefix: list[tuple[int, int]] = []
                    remaining = depth
                    for direction, count in path:
                        take = min(remaining, count)
                        prefix.append((direction, take))
                        remaining -= take
                        if remaining == 0:
                            break
                    decoded = _decode_path(prefix)
                    if decoded is None:
                        return INVALID_RESULT, b""
                    words.extend((operation, decoded[0], decoded[1]))
            elif operation == 4:  # RANGE
                if position + 2 > len(values):
                    return INVALID_RESULT, b""
                numerator, denominator = values[position:position + 2]
                position += 2
                if not _valid_fraction(numerator, denominator):
                    return INVALID_RESULT, b""
                decoded = _decode_path(_encode_path(numerator, denominator))
                if decoded is None:
                    return INVALID_RESULT, b""
                words.extend((operation, decoded[2], decoded[3], decoded[4], decoded[5]))
            else:
                return INVALID_RESULT, b""
    except ValueError:
        return INVALID_RESULT, b""
    if position != len(values) or len(words) * 8 > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    return query_count, b"".join(struct.pack("<q", word) for word in words)

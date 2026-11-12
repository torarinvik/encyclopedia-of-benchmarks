"""Divide-and-conquer Main–Lorentz oracle for tandem-square intervals."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 24
MAX_REPETITIONS = MAX_N * MAX_N // 4
MAX_INPUT_LENGTH = MAX_N + 1
MAX_OUTPUT_BYTES = 8 * (1 + MAX_REPETITIONS)
MAX_WORKSPACE_BYTES = 16384
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _z_values(sequence: list[int]) -> list[int]:
    z = [0] * len(sequence)
    left = 0
    right = -1
    for index in range(1, len(sequence)):
        if index <= right:
            z[index] = min(right - index + 1, z[index - left])
        while index + z[index] < len(sequence) and sequence[z[index]] == sequence[index + z[index]]:
            z[index] += 1
        if index + z[index] - 1 > right:
            left = index
            right = index + z[index] - 1
    return z


def _at(z: list[int], index: int) -> int:
    return z[index] if 0 <= index < len(z) else 0


def _main_lorentz(symbols: list[int]) -> list[tuple[int, int]]:
    n = len(symbols)
    marked = [[False] * (n // 2 + 1) for _ in range(n)]

    def divide(lo: int, hi: int) -> None:
        length = hi - lo
        if length <= 1:
            return
        left_size = length // 2
        mid = lo + left_size
        right_size = length - left_size
        left = symbols[lo:mid]
        right = symbols[mid:hi]
        reverse_left = left[::-1]
        reverse_right = right[::-1]

        divide(lo, mid)
        divide(mid, hi)

        z_left_reverse = _z_values(reverse_left)
        z_right_then_left = _z_values(right + [-1] + left)
        z_reverse_left_then_reverse_right = _z_values(reverse_left + [-1] + reverse_right)
        z_right = _z_values(right)

        for center in range(length):
            if center < left_size:
                half = left_size - center
                matched_before = _at(z_left_reverse, left_size - center)
                matched_after = _at(z_right_then_left, right_size + 1 + center)
                left_biased = True
            else:
                in_right = center - left_size
                half = in_right + 1
                matched_before = _at(
                    z_reverse_left_then_reverse_right,
                    left_size + 1 + right_size - 1 - in_right,
                )
                matched_after = _at(z_right, in_right + 1)
                left_biased = False
            if matched_before + matched_after < half:
                continue

            first_min = max(1, half - matched_after)
            first_max = min(half, matched_before)
            for first_half in range(first_min, first_max + 1):
                if left_biased and first_half == half:
                    continue
                start = (
                    center - first_half
                    if left_biased
                    else center - half - first_half + 1
                )
                marked[lo + start][half] = True

    if n > 1:
        divide(0, n)
    return [
        (start, half)
        for start in range(n)
        for half in range(1, n // 2 + 1)
        if start + 2 * half <= n and marked[start][half]
    ]


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> list[int] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != n + 1:
        return None
    symbols = list(values[1:])
    if any(symbol < 0 or symbol > 255 for symbol in symbols):
        return None
    return symbols


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    symbols = _parse(values, input_is_null, input_length)
    if symbols is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    repetitions = _main_lorentz(symbols)
    words = [len(repetitions)] + [start * 32 + half for start, half in repetitions]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (output_capacity is not None and output_capacity < len(payload)):
        return OUTPUT_ERROR, b""
    return len(payload), payload

"""Rotating-ring construction, independent of the modular pair formula."""

from __future__ import annotations

from collections.abc import Sequence

MIN_TEAMS = 2
MAX_TEAMS = 8
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 58
MAX_WORKSPACE_BYTES = 128
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _read_teams(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length > 2
    ):
        return None
    if input_is_null or not isinstance(values, (tuple, list)):
        return None
    if not values or len(values) > 2:
        return None
    if input_length is not None and len(values) != input_length:
        return None
    for value in values:
        if type(value) is not int or not I64_MIN <= value <= I64_MAX:
            return None
    if len(values) != 1 or values[0] < 2 or values[0] > 8:
        return None
    return values[0]


def _rotating_table(n: int) -> tuple[int, list[int]]:
    padded_count = n + (n & 1)
    pivot = padded_count - 1
    rotating = list(range(pivot))
    rounds = len(rotating)
    table = [255] * (n * rounds)
    for round_index in range(rounds):
        first = rotating[0]
        if pivot < n:
            table[pivot * rounds + round_index] = first
            table[first * rounds + round_index] = pivot
        for pair_index in range(1, padded_count // 2):
            left = rotating[pair_index]
            right = rotating[rounds - pair_index]
            table[left * rounds + round_index] = right
            table[right * rounds + round_index] = left
        rotating = rotating[1:] + rotating[:1]
    return rounds, table


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    n = _read_teams(values, input_is_null, input_length)
    if n is None:
        return -1, b""
    rounds, table = _rotating_table(n)
    payload = bytes((n, rounds, *table))
    if type(output_is_null) is not bool:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -2, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload

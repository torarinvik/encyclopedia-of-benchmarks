"""Modular-pair construction for a canonical single round-robin schedule."""

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


def _team_count(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    if len(values) != 1:
        return None
    n = values[0]
    if not MIN_TEAMS <= n <= MAX_TEAMS:
        return None
    return n


def _formula_table(n: int) -> tuple[int, list[int]]:
    padded = n if n % 2 == 0 else n + 1
    ring_size = padded - 1
    rounds = ring_size
    fixed = padded - 1
    table = [255] * (n * rounds)
    for round_index in range(rounds):
        if fixed < n:
            table[fixed * rounds + round_index] = round_index
            table[round_index * rounds + round_index] = fixed
        for offset in range(1, padded // 2):
            left = (round_index + offset) % ring_size
            right = (round_index - offset) % ring_size
            if left < n and right < n:
                table[left * rounds + round_index] = right
                table[right * rounds + round_index] = left
    return rounds, table


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    n = _team_count(values, input_is_null, input_length)
    if n is None:
        return -1, b""
    rounds, table = _formula_table(n)
    payload = bytes((n, rounds, *table))
    if type(output_is_null) is not bool:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -2, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload

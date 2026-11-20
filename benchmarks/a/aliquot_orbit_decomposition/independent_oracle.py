"""Factorization and linear-history reference for aliquot orbits."""

from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_INPUT_LENGTH,
    MAX_SEED,
    MAX_TRANSITIONS,
    MAX_VALUE,
    OUTPUT_BYTES,
)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX
           for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    seed, max_transitions = values
    if not 1 <= seed <= MAX_SEED or not 1 <= max_transitions <= MAX_TRANSITIONS:
        return None
    return seed, max_transitions


def _aliquot_by_factorization(value: int) -> int:
    remaining = value
    sigma = 1
    prime = 2
    while prime <= remaining // prime:
        if remaining % prime == 0:
            prime_power = 1
            geometric_sum = 1
            while remaining % prime == 0:
                remaining //= prime
                prime_power *= prime
                geometric_sum += prime_power
            sigma *= geometric_sum
        prime = 3 if prime == 2 else prime + 2
    if remaining > 1:
        sigma *= 1 + remaining
    return sigma - value


def _decompose_by_linear_history(seed: int, max_transitions: int) -> list[int]:
    history: list[int] = []
    current = seed
    transitions = 0
    while True:
        if current == 0:
            return [0, len(history), 0]
        try:
            first_index = history.index(current)
        except ValueError:
            first_index = -1
        if first_index >= 0:
            return [1, first_index, len(history) - first_index]
        history.append(current)
        if transitions >= max_transitions:
            return [-3, transitions, current]
        next_value = _aliquot_by_factorization(current)
        transitions += 1
        if next_value > MAX_VALUE:
            return [-2, transitions, next_value]
        current = next_value


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    words = _decompose_by_linear_history(*parsed)
    encoded = b"".join(struct.pack("<q", word) for word in words)
    actual_capacity = OUTPUT_BYTES if capacity is None else capacity
    if type(output_is_null) is not bool or type(actual_capacity) is not int or actual_capacity < 0:
        return -2, b""
    if output_is_null or actual_capacity < OUTPUT_BYTES:
        return -2, b""
    return OUTPUT_BYTES, encoded

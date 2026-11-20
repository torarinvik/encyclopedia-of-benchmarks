"""First-seen-index reference for bounded aliquot orbit decomposition."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_SEED = 100_000
MAX_VALUE = 100_000
MAX_TRANSITIONS = 4_096
MAX_INPUT_LENGTH = 3
OUTPUT_BYTES = 24
WORKSPACE_BYTES = 200_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    seed, max_transitions = values
    if not 1 <= seed <= MAX_SEED or not 1 <= max_transitions <= MAX_TRANSITIONS:
        return None
    return seed, max_transitions


def _aliquot_by_divisor_pairs(value: int) -> int:
    if value == 1:
        return 0
    total = 1
    divisor = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            total += divisor
            partner = value // divisor
            if partner != divisor:
                total += partner
        divisor += 1
    return total


def _decompose(seed: int, max_transitions: int) -> list[int]:
    first_seen: dict[int, int] = {}
    current = seed
    transitions = 0
    positive_term_count = 0
    while True:
        if current == 0:
            return [0, positive_term_count, 0]
        first_index = first_seen.get(current)
        if first_index is not None:
            return [1, first_index, transitions - first_index]
        first_seen[current] = transitions
        positive_term_count += 1
        if transitions >= max_transitions:
            return [-3, transitions, current]
        next_value = _aliquot_by_divisor_pairs(current)
        transitions += 1
        if next_value > MAX_VALUE:
            return [-2, transitions, next_value]
        current = next_value


def _encode(words: Sequence[int]) -> bytes:
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    words = _decompose(*parsed)
    encoded = _encode(words)
    actual_capacity = OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(actual_capacity) is not int
            or actual_capacity < 0):
        return -2, b""
    if output_is_null or actual_capacity < OUTPUT_BYTES:
        return -2, b""
    return OUTPUT_BYTES, encoded

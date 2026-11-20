"""Multiplicative-order reference for perfect out-shuffle restoration."""

from __future__ import annotations

from .primary_oracle import MAX_DECK_SIZE, MAX_PARSEABLE_INPUT_LENGTH


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if len(values) != 1:
        return -1
    deck_size = values[0]
    if not 2 <= deck_size <= MAX_DECK_SIZE or deck_size % 2 != 0:
        return -1

    modulus = deck_size - 1
    if modulus == 1:
        return 1
    residue = 2 % modulus
    order = 1
    while residue != 1:
        residue = residue * 2 % modulus
        order += 1
    return order

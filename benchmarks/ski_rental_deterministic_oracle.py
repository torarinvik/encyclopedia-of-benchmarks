"""Bounded direct-threshold oracle for deterministic ski rental."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 32


def _decode(values: Sequence[int] | None) -> tuple[int, int, int] | None:
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if len(values) != 3:
        return None
    rent, purchase, trips = values
    if not 1 <= rent <= 32 or not 1 <= purchase <= 64 or not 0 <= trips <= 32:
        return None
    return rent, purchase, trips


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    rent, purchase, trips = decoded
    rentals_before_purchase = purchase // rent
    actions = bytearray()
    for trip in range(trips):
        if trip < rentals_before_purchase:
            actions.append(0)
        elif trip == rentals_before_purchase:
            actions.append(1)
        else:
            actions.append(2)
    payload = bytes(actions)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload

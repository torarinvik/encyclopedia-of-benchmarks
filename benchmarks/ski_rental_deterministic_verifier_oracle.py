"""Independent state-simulation verifier for deterministic ski rental."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 32


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if len(values) != 3:
        return None
    rent, purchase, trips = values
    if rent < 1 or rent > 32 or purchase < 1 or purchase > 64 or trips < 0 or trips > 32:
        return None
    return rent, purchase, trips


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or values is None:
        return invalid, b""
    decoded = _decode(values)
    if decoded is None:
        return invalid, b""
    rent, purchase, trips = decoded
    actions = bytearray()
    rent_count = 0
    bought = False
    for _ in range(trips):
        if bought:
            actions.append(2)
        elif rent_count == purchase // rent:
            actions.append(1)
            bought = True
        else:
            actions.append(0)
            rent_count += 1
    payload = bytes(actions)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload

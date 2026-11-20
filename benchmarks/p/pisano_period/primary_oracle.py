"""Linear modular-pair reference for the Pisano period."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MODULUS = 64
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 1_024


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    modulus = values[0]
    if not 1 <= modulus <= MAX_MODULUS:
        return None
    return modulus


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    modulus = _parse(values, input_length, input_is_null)
    if modulus is None:
        return -1
    start = (0, 1 % modulus)
    previous, current = start
    for period in range(1, 6 * modulus + 1):
        previous, current = current, (previous + current) % modulus
        if (previous, current) == start:
            return period
    return -1

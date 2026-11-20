"""Direct candidate-root scan, independent of extension-field arithmetic."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PRIME = 1_000_003
MAX_PARSEABLE_INPUT_LENGTH = 3


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
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
    if len(values) != 2:
        return -1
    residue, prime = values
    if prime < 3 or prime > MAX_PRIME or prime % 2 == 0 or not 0 <= residue < prime:
        return -1
    for candidate in range(prime):
        if candidate * candidate % prime == residue:
            return min(candidate, prime - candidate)
    return -1

"""Fast-doubling scan reference for the Pisano period."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import MAX_MODULUS


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> int | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or len(values) != 1:
        return None
    if type(values[0]) is not int:
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    modulus = values[0]
    if not 1 <= modulus <= MAX_MODULUS:
        return None
    return modulus


def _fibonacci_pair(index: int, modulus: int) -> tuple[int, int]:
    """Return (F(index), F(index+1)) modulo modulus by binary doubling."""
    a, b = 0, 1 % modulus
    for bit in bin(index)[2:]:
        even = (a * ((2 * b - a) % modulus)) % modulus
        odd = (a * a + b * b) % modulus
        if bit == "0":
            a, b = even, odd
        else:
            a, b = odd, (even + odd) % modulus
    return a, b


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    modulus = _parse(values, input_length, input_is_null)
    if modulus is None:
        return -1
    target = (0, 1 % modulus)
    for index in range(1, 6 * modulus + 1):
        if _fibonacci_pair(index, modulus) == target:
            return index
    return -1

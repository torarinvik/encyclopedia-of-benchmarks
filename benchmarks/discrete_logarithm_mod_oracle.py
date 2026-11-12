"""Direct power-enumeration oracle for the bounded discrete-log workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_MODULUS = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the least nonnegative k with x**k == y (mod m), or -1."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) != 3
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT
    x, y, modulus = values
    if not 1 <= modulus <= MAX_MODULUS or not 0 <= x < modulus or not 0 <= y < modulus:
        return INVALID_RESULT

    # Start at k=0, which also models the required 0**0 == 1 convention.
    residue = 1 % modulus
    seen: set[int] = set()
    exponent = 0
    while residue not in seen:
        if residue == y:
            return exponent
        seen.add(residue)
        residue = (residue * x) % modulus
        exponent += 1
    return -1

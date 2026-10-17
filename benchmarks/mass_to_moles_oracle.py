"""Oracle for the bounded Python molecular-chemistry mass-to-moles method."""

from __future__ import annotations

INVALID_RESULT = -1.0e300
MAX_INPUT_LENGTH = 3  # includes one overlong malformed case
MAX_MASS = 1_000
MIN_MOLAR_MASS = 1
MAX_MOLAR_MASS = 1_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return rounded moles or the finite invalid-input sentinel."""
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    mass, molar_mass = values
    if not 0 <= mass <= MAX_MASS:
        return INVALID_RESULT
    if not MIN_MOLAR_MASS <= molar_mass <= MAX_MOLAR_MASS:
        return INVALID_RESULT

    return round(float(mass / molar_mass), 2)

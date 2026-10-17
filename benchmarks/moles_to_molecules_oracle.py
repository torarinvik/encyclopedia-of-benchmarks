"""Oracle for the bounded Python molecular-chemistry molecule conversion."""

from __future__ import annotations

MAX_INPUT_LENGTH = 2  # includes one extra-value malformed case
SCALE = 1_000_000
MAX_MOLES_MICRO = 2_000_000
INVALID_RESULT = -1.0e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Convert scaled moles using the source's binary64/format/parse order."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    if len(values) != 1:
        return INVALID_RESULT
    moles_micro = values[0]
    if not 0 <= moles_micro <= MAX_MOLES_MICRO:
        return INVALID_RESULT

    moles = moles_micro / SCALE
    # The workload's 175-micro-mole case is an exact decimal halfway value;
    # Python's `.4e` formatting resolves it with ties-to-even.
    formatted = f"{moles * 6.022e23:.4e}"
    return float(formatted)

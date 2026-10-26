"""Independent oracle for the bounded BEEBS 32-bit bit-compress operation."""

from collections.abc import Sequence

MAX_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_U32 = (1 << 32) - 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None) -> int:
    """Pack selected data bits into consecutive low-order result bits."""
    if not isinstance(values, Sequence) or len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or value < 0 or value > MAX_U32 for value in values):
        return INVALID_RESULT

    data, mask = values
    packed = 0
    remaining = mask
    while remaining:
        lowest_selected = remaining & -remaining
        if data & lowest_selected:
            destination = (mask & (lowest_selected - 1)).bit_count()
            packed |= 1 << destination
        remaining ^= lowest_selected
    return packed

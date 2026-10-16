"""Oracle for the bounded, source-faithful AArch64 JortSort routine."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_INPUT_LENGTH = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return 1 iff the pinned routine's sorted copy equals the input."""
    if (not isinstance(values, (list, tuple)) or not 0 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    copied = list(values)
    # The pinned AArch64 insertion loop skips its comparison when the
    # predecessor index reaches zero. This leaves copied[0] fixed and sorts
    # only the suffix copied[1:].
    for index in range(2, len(copied)):
        key = copied[index]
        position = index
        while position > 1 and copied[position - 1] > key:
            copied[position] = copied[position - 1]
            position -= 1
        copied[position] = key
    return int(copied == list(values))

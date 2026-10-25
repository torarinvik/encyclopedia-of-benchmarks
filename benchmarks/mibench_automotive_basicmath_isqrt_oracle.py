"""Independent oracle for the bounded MiBench fixed-point integer square root."""

from __future__ import annotations

MAX_VALUE = 65_535
MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1
_U32_MASK = (1 << 32) - 1


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_VALUE):
        return INVALID_RESULT

    x = values[0]
    accumulator = 0
    remainder = 0
    for _ in range(32):
        remainder = ((remainder << 2) + (x >> 30)) & _U32_MASK
        x = (x << 2) & _U32_MASK
        accumulator = (accumulator << 1) & _U32_MASK
        trial = ((accumulator << 1) + 1) & _U32_MASK
        if remainder >= trial:
            remainder = (remainder - trial) & _U32_MASK
            accumulator = (accumulator + 1) & _U32_MASK
    return accumulator

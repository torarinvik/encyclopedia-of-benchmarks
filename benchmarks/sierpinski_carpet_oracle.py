"""Independent oracle for the bounded Sierpinski carpet raster."""

from collections.abc import Sequence

MIN_DEPTH = 0
MAX_DEPTH = 4
VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
PRINTABLE_ASCII_MIN = 32
PRINTABLE_ASCII_MAX = 126
MAX_SIDE = 3**MAX_DEPTH
MAX_OUTPUT_BYTES = 8 + MAX_SIDE * MAX_SIDE + MAX_SIDE - 1
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _i64_le(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def is_filled(row: int, col: int) -> bool:
    while row or col:
        if row % 3 == 1 and col % 3 == 1:
            return False
        row //= 3
        col //= 3
    return True


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple))
            or not VALID_INPUT_LENGTH <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""
    depth, filled, hole = values[:3]
    if len(values) != VALID_INPUT_LENGTH or not MIN_DEPTH <= depth <= MAX_DEPTH:
        return INVALID_RESULT, b""
    if (not PRINTABLE_ASCII_MIN <= filled <= PRINTABLE_ASCII_MAX
            or not PRINTABLE_ASCII_MIN <= hole <= PRINTABLE_ASCII_MAX or filled == hole):
        return INVALID_RESULT, b""

    side = 3**depth
    rows = [
        bytes(filled if is_filled(row, col) else hole for col in range(side))
        for row in range(side)
    ]
    raster = b"\n".join(rows)
    output = _i64_le(side) + raster
    if capacity is not None and (type(capacity) is not int or capacity < len(output)):
        return CAPACITY_ERROR, b""
    return len(output), output

"""Four-state frontier reference for domino/L-tromino 2-by-n tilings."""
from __future__ import annotations

MAX_WIDTH = 32
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 256


def _parse(values, *, input_length: int | None = None,
           input_is_null: bool = False) -> int | None:
    if (values is None or input_is_null or not isinstance(values, (list, tuple))
            or len(values) != 1):
        return None
    if type(values[0]) is not int or not -(1 << 63) <= values[0] < (1 << 63):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != 1):
        return None
    width = values[0]
    return width if 0 <= width <= MAX_WIDTH else None


def frontier_count(width: int) -> int | None:
    if type(width) is not int or not 0 <= width <= MAX_WIDTH:
        return None
    # State bits mark cells already occupied in the current column by tiles
    # crossing from the previous column. Entries are masks 00, 01, 10, 11.
    dp0, dp1, dp2, dp3 = 1, 0, 0, 0
    for _ in range(width):
        next0 = dp0 + dp3
        next1 = dp0 + dp2
        next2 = dp0 + dp1
        next3 = dp0 + dp1 + dp2
        dp0, dp1, dp2, dp3 = next0, next1, next2, next3
    return dp0


def expected_result(values, *, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    width = _parse(values, input_length=input_length, input_is_null=input_is_null)
    if width is None:
        return -1
    result = frontier_count(width)
    return -1 if result is None else result

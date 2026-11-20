"""Iterative grammar rewriting for the Wirth Sierpinski curve trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OUTPUT_BYTES = 64
MAX_PARSEABLE_INPUT_LENGTH = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

# Symbols 0..3 denote A/B/C/D. Symbols 4..19 encode a direction byte.
RULES: dict[int, tuple[int, ...]] = {
    0: (0, 11, 1, 12, 3, 5, 0),  # A: A,7,B,8,D,1,A
    1: (1, 9, 2, 18, 0, 11, 1),  # B: B,5,C,14,A,7,B
    2: (2, 7, 3, 16, 1, 9, 2),  # C: C,3,D,12,B,5,C
    3: (3, 5, 0, 14, 2, 7, 3),  # D: D,1,A,10,C,3,D
}


def _read_order(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (
        type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if input_is_null or not isinstance(values, (tuple, list)):
        return None
    if not values or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and len(values) != input_length:
        return None
    for value in values:
        if type(value) is not int or not I64_MIN <= value <= I64_MAX:
            return None
    if len(values) != 1 or values[0] < 0 or values[0] > 2:
        return None
    return values[0]


def _rewritten_moves(order: int) -> bytes:
    # Root phrase is A,7,B,5,C,3,D,1; line tokens are stored as 4+code.
    stream: list[tuple[int, int]] = [
        (0, order), (11, 0), (1, order), (9, 0),
        (2, order), (7, 0), (3, order), (5, 0),
    ]
    while any(symbol < 4 for symbol, _level in stream):
        rewritten: list[tuple[int, int]] = []
        for symbol, level in stream:
            if symbol >= 4:
                rewritten.append((symbol, 0))
            elif level == 0:
                continue
            else:
                rewritten.extend((child, level - 1) for child in RULES[symbol])
        stream = rewritten
    return bytes(symbol - 4 for symbol, _level in stream)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    order = _read_order(values, input_is_null, input_length)
    if order is None:
        return -1, b""
    payload = _rewritten_moves(order)
    if type(output_is_null) is not bool:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -2, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload

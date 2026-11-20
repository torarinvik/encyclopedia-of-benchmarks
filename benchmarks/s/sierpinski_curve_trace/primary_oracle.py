"""Recursive Wirth A/B/C/D construction for the Sierpinski curve trace."""

from __future__ import annotations

from collections.abc import Sequence

MIN_ORDER = 0
MAX_ORDER = 2
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 64
MAX_WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _order(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (
        type(input_length) is not int
        or input_length < 0
        or input_length > MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and len(values) != input_length:
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return None
    if len(values) != 1 or not MIN_ORDER <= values[0] <= MAX_ORDER:
        return None
    return values[0]


def _recursive_moves(order: int) -> list[int]:
    moves: list[int] = []

    def a(level: int) -> None:
        if level == 0:
            return
        a(level - 1)
        moves.append(7)
        b(level - 1)
        moves.append(8)  # direction 0, length 2h
        d(level - 1)
        moves.append(1)
        a(level - 1)

    def b(level: int) -> None:
        if level == 0:
            return
        b(level - 1)
        moves.append(5)
        c(level - 1)
        moves.append(14)  # direction 6, length 2h
        a(level - 1)
        moves.append(7)
        b(level - 1)

    def c(level: int) -> None:
        if level == 0:
            return
        c(level - 1)
        moves.append(3)
        d(level - 1)
        moves.append(12)  # direction 4, length 2h
        b(level - 1)
        moves.append(5)
        c(level - 1)

    def d(level: int) -> None:
        if level == 0:
            return
        d(level - 1)
        moves.append(1)
        a(level - 1)
        moves.append(10)  # direction 2, length 2h
        c(level - 1)
        moves.append(3)
        d(level - 1)

    a(order)
    moves.append(7)
    b(order)
    moves.append(5)
    c(order)
    moves.append(3)
    d(order)
    moves.append(1)
    return moves


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    order = _order(values, input_is_null, input_length)
    if order is None:
        return -1, b""
    payload = bytes(_recursive_moves(order))
    if type(output_is_null) is not bool:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -2, b""
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload

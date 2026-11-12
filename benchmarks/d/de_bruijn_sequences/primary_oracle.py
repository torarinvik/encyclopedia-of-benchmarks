"""Primary FKM generator for the bounded de Bruijn sequence profile."""
from __future__ import annotations

from collections.abc import Sequence

MAX_ORDER = 16
MAX_CYCLE_LENGTH = 10_000
MAX_OUTPUT_BYTES = 10_003
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) != 2
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    alphabet, order = values
    if not 2 <= alphabet <= 10 or not 1 <= order <= MAX_ORDER:
        return None
    if alphabet ** order > MAX_CYCLE_LENGTH:
        return None
    return alphabet, order


def _generate(alphabet: int, order: int) -> bytes:
    work = [0] * (order + 1)
    cycle: list[int] = []

    def visit(position: int, period: int) -> None:
        if position > order:
            if order % period == 0:
                cycle.extend(work[1:period + 1])
            return
        work[position] = work[position - period]
        visit(position + 1, period)
        for symbol in range(work[position - period] + 1, alphabet):
            work[position] = symbol
            visit(position + 1, position)

    visit(1, 1)
    return bytes(48 + symbol for symbol in cycle + cycle[:order - 1])


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    sequence = _generate(*parsed)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(sequence)):
        return OUTPUT_ERROR_RESULT, b""
    return len(sequence), sequence


def validate_output(values: Sequence[int] | None, output: bytes) -> bool:
    result, expected = expected_output(values, capacity=MAX_OUTPUT_BYTES)
    return result == len(expected) and output == expected

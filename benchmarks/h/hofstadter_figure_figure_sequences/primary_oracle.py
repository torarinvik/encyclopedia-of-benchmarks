"""Incremental recurrence reference for Hofstadter's Figure-Figure pair."""
from __future__ import annotations

from struct import pack

MAX_TERMS = 64
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = (1 + 2 * MAX_TERMS) * 8
WORKSPACE_BYTES = 4096


def _parse(values, input_is_null: bool, input_length: int | None):
    if (values is None or input_is_null or not isinstance(values, (list, tuple))
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if input_length is not None and input_length != MAX_VALID_INPUT_LENGTH:
        return None
    terms = values[0]
    if not 1 <= terms <= MAX_TERMS:
        return None
    return terms


def solve(values, *, input_is_null: bool = False,
          input_length: int | None = None) -> tuple[list[int], list[int]] | None:
    terms = _parse(values, input_is_null, input_length)
    if terms is None:
        return None
    figure = [0] * terms
    space = [0] * terms
    figure[0] = 1
    space[0] = 2
    next_candidate = 3
    for index in range(1, terms):
        figure[index] = figure[index - 1] + space[index - 1]
        while next_candidate in figure[:index + 1]:
            next_candidate += 1
        space[index] = next_candidate
        next_candidate += 1
    return figure, space


def expected_output(values, *, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    result = solve(values, input_is_null=input_is_null, input_length=input_length)
    if result is None:
        return -1, b""
    figure, space = result
    size = (1 + 2 * len(figure)) * 8
    if output_is_null or (capacity is not None and capacity < size):
        return -2, b""
    words = [len(figure), *figure, *space]
    return size, b"".join(pack("<q", word) for word in words)

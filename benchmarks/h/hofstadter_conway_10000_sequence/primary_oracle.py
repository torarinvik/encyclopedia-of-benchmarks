"""Bottom-up reference for a bounded Hofstadter-Conway sequence prefix."""
from __future__ import annotations

MAX_INDEX = 8192
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = (MAX_INDEX + 1) * 8


def _parse(values, *, input_is_null: bool = False,
           input_length: int | None = None) -> int | None:
    if (values is None or input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    if (input_length is not None
            and (type(input_length) is not int
                 or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return None
    if input_length is not None and input_length != MAX_VALID_INPUT_LENGTH:
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    index = values[0]
    if not 2 <= index <= MAX_INDEX:
        return None
    return index


def sequence_term(index: int) -> int | None:
    if type(index) is not int or not 1 <= index <= MAX_INDEX:
        return None
    terms = [0] * (index + 1)
    terms[1] = 1
    if index >= 2:
        terms[2] = 1
    for current in range(3, index + 1):
        previous = terms[current - 1]
        other = current - previous
        if not (1 <= previous < current and 1 <= other < current):
            return None
        terms[current] = terms[previous] + terms[other]
    return terms[index]


def expected_result(values, *, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    index = _parse(values, input_length=input_length, input_is_null=input_is_null)
    if index is None:
        return -1
    result = sequence_term(index)
    return -1 if result is None else result
